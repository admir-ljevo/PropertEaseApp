using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Services.Services.PropertyReservationService;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace PropertEase.Services.Services.PaymentService
{
    public class PaymentService : IPaymentService
    {
        private readonly UnitOfWork _unitOfWork;
        private readonly IPropertyReservationService _reservationService;
        private readonly IConfiguration _configuration;
        private readonly IRabbitMQPublisher _publisher;

        public PaymentService(
            IUnitOfWork unitOfWork,
            IPropertyReservationService reservationService,
            IConfiguration configuration,
            IRabbitMQPublisher publisher)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _reservationService = reservationService;
            _configuration = configuration;
            _publisher = publisher;
        }

        public object GetPayPalConfig()
        {
            var mode = _configuration["PayPal:Mode"] ?? "sandbox";
            return new
            {
                ClientId = _configuration["PayPal:ClientId"],
                SecretKey = mode == "sandbox" ? _configuration["PayPal:Secret"] : null,
                SandboxMode = mode == "sandbox"
            };
        }

        public async Task<PropertyReservationDto> CompleteReservationAsync(CompleteReservationPaymentDto dto)
        {
            await VerifyPayPalPaymentAsync(dto.PayPalPaymentId, dto.Amount);

            var payment = new Payment
            {
                ClientId = dto.ClientId,
                PayPalPaymentId = dto.PayPalPaymentId,
                PayPalPayerId = dto.PayPalPayerId,
                Amount = dto.Amount,
                Currency = "USD",
                Status = "Completed",
                Description = $"Reservation for property {dto.PropertyId}",
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false,
            };
            await _unitOfWork.PaymentRepository.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            var reservationDto = new PropertyReservationDto
            {
                PropertyId = dto.PropertyId,
                ClientId = dto.ClientId,
                RenterId = dto.RenterId,
                NumberOfGuests = dto.NumberOfGuests,
                DateOfOccupancyStart = dto.DateOfOccupancyStart,
                DateOfOccupancyEnd = dto.DateOfOccupancyEnd,
                NumberOfDays = dto.NumberOfDays,
                NumberOfMonths = dto.NumberOfMonths,
                TotalPrice = dto.TotalPrice,
                IsMonthly = dto.IsMonthly,
                IsDaily = dto.IsDaily,
                Description = dto.Description,
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
            };

            var created = await _reservationService.AddAsync(reservationDto);

            payment.ReservationId = created.Id;
            _unitOfWork.PaymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();

            return created;
        }

        public async Task RefundReservationAsync(int reservationId, bool enforceSevenDayRule)
        {
            var db = _unitOfWork.GetDatabaseContext();

            var reservation = await db.PropertyReservations.FindAsync(reservationId);
            if (reservation == null || reservation.IsDeleted)
                throw new InvalidOperationException("Reservation not found.");

            if (!reservation.IsActive)
                throw new InvalidOperationException("Reservation is already inactive.");

            if (enforceSevenDayRule)
            {
                var daysUntilCheckIn = (reservation.DateOfOccupancyStart - DateTime.UtcNow).TotalDays;
                if (daysUntilCheckIn < 7)
                    throw new InvalidOperationException(
                        "Cancellation is only allowed more than 7 days before check-in.");
            }

            var payment = await _unitOfWork.PaymentRepository.GetByReservationIdAsync(reservationId);

            if (payment != null && !string.IsNullOrEmpty(payment.PayPalPaymentId)
                && payment.Status != "Refunded")
            {
                await RefundPayPalPaymentAsync(payment.PayPalPaymentId, payment.Amount);
                payment.Status = "Refunded";
                _unitOfWork.PaymentRepository.Update(payment);
            }

            reservation.IsActive = false;
            db.PropertyReservations.Update(reservation);

            await _unitOfWork.SaveChangesAsync();

            // Publish cancellation messages via RabbitMQ
            try
            {
                var property = await db.Properties
                    .Where(p => p.Id == reservation.PropertyId)
                    .FirstOrDefaultAsync();

                var client = await db.Users
                    .Include(u => u.Person)
                    .FirstOrDefaultAsync(u => u.Id == reservation.ClientId);

                var renter = reservation.RenterId > 0
                    ? await db.Users.Include(u => u.Person)
                        .FirstOrDefaultAsync(u => u.Id == reservation.RenterId)
                    : null;

                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == reservation.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                var propertyName = property?.Name ?? string.Empty;
                var reservationNumber = reservation.ReservationNumber ?? $"#{reservation.Id:D4}";
                var cancellationReason = enforceSevenDayRule
                    ? "Otkazano od strane klijenta"
                    : "Otkazano od strane iznajmljivača/admina";

                _publisher.Publish(new
                {
                    ReservationId = reservation.Id,
                    ReservationNumber = reservationNumber,
                    PropertyName = propertyName,
                    CancellationReason = cancellationReason,
                    CheckIn = reservation.DateOfOccupancyStart,
                    CheckOut = reservation.DateOfOccupancyEnd,
                    TotalPrice = (decimal)(payment?.Amount ?? 0),
                    PropertyPhotoUrl = photoUrl,
                    ClientUserId = reservation.ClientId,
                    ClientEmail = client?.Email ?? string.Empty,
                    ClientFullName = $"{client?.Person?.FirstName} {client?.Person?.LastName}".Trim(),
                    RenterUserId = reservation.RenterId,
                    RenterEmail = renter?.Email ?? string.Empty,
                    RenterFullName = $"{renter?.Person?.FirstName} {renter?.Person?.LastName}".Trim(),
                }, "reservation.cancelled");
            }
            catch
            {
                // messaging failure must not roll back the refund
            }
        }

        private async Task RefundPayPalPaymentAsync(string paymentId, double amount)
        {
            var clientId = _configuration["PayPal:ClientId"];
            var secret = _configuration["PayPal:Secret"];

            if (string.IsNullOrEmpty(clientId) || clientId.StartsWith("REPLACE") ||
                string.IsNullOrEmpty(secret) || secret.StartsWith("REPLACE"))
                return; // skip in dev if credentials are placeholders

            var mode = _configuration["PayPal:Mode"] ?? "sandbox";
            var baseUrl = mode == "sandbox"
                ? "https://api.sandbox.paypal.com"
                : "https://api.paypal.com";

            using var http = new HttpClient();

            // Get access token
            var credentials = Convert.ToBase64String(
                Encoding.UTF8.GetBytes($"{clientId}:{secret}"));
            var tokenReq = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v1/oauth2/token");
            tokenReq.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
            tokenReq.Content = new StringContent(
                "grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

            var tokenRes = await http.SendAsync(tokenReq);
            tokenRes.EnsureSuccessStatusCode();
            var tokenData = JsonSerializer.Deserialize<JsonElement>(
                await tokenRes.Content.ReadAsStringAsync());
            var accessToken = tokenData.GetProperty("access_token").GetString()!;

            // Fetch payment to get the sale ID
            var paymentReq = new HttpRequestMessage(
                HttpMethod.Get, $"{baseUrl}/v1/payments/payment/{paymentId}");
            paymentReq.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);
            var paymentRes = await http.SendAsync(paymentReq);
            paymentRes.EnsureSuccessStatusCode();
            var paymentData = JsonSerializer.Deserialize<JsonElement>(
                await paymentRes.Content.ReadAsStringAsync());

            var saleId = paymentData
                .GetProperty("transactions")[0]
                .GetProperty("related_resources")[0]
                .GetProperty("sale")
                .GetProperty("id")
                .GetString()!;

            // Issue refund
            var refundBody = JsonSerializer.Serialize(new
            {
                amount = new
                {
                    total = amount.ToString("F2"),
                    currency = "USD"
                }
            });
            var refundReq = new HttpRequestMessage(
                HttpMethod.Post, $"{baseUrl}/v1/payments/sale/{saleId}/refund");
            refundReq.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", accessToken);
            refundReq.Content = new StringContent(refundBody, Encoding.UTF8, "application/json");

            var refundRes = await http.SendAsync(refundReq);
            if (!refundRes.IsSuccessStatusCode)
            {
                var err = await refundRes.Content.ReadAsStringAsync();
                throw new InvalidOperationException($"PayPal refund failed: {err}");
            }
        }

        private async Task VerifyPayPalPaymentAsync(string paymentId, double expectedAmount)
        {
            var clientId = _configuration["PayPal:ClientId"];
            var secret = _configuration["PayPal:Secret"];

            // Skip verification if credentials are still placeholders
            if (string.IsNullOrEmpty(clientId) || clientId.StartsWith("REPLACE") ||
                string.IsNullOrEmpty(secret) || secret.StartsWith("REPLACE"))
                return;

            var mode = _configuration["PayPal:Mode"] ?? "sandbox";
            var baseUrl = mode == "sandbox"
                ? "https://api.sandbox.paypal.com"
                : "https://api.paypal.com";

            using var http = new HttpClient();

            // Get access token
            var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{secret}"));
            var tokenReq = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v1/oauth2/token");
            tokenReq.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
            tokenReq.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

            var tokenRes = await http.SendAsync(tokenReq);
            tokenRes.EnsureSuccessStatusCode();
            var tokenData = JsonSerializer.Deserialize<JsonElement>(await tokenRes.Content.ReadAsStringAsync());
            var accessToken = tokenData.GetProperty("access_token").GetString()!;

            // Verify payment
            var paymentReq = new HttpRequestMessage(HttpMethod.Get, $"{baseUrl}/v1/payments/payment/{paymentId}");
            paymentReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            var paymentRes = await http.SendAsync(paymentReq);
            paymentRes.EnsureSuccessStatusCode();
            var paymentData = JsonSerializer.Deserialize<JsonElement>(await paymentRes.Content.ReadAsStringAsync());

            var state = paymentData.GetProperty("state").GetString();
            if (state != "approved" && state != "created")
                throw new InvalidOperationException($"PayPal payment state is '{state}', expected 'approved'.");
        }
    }
}
