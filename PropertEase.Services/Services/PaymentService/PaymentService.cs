using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;
using PropertEase.Core.StateMachines;
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
        private const string ReturnUrl = "https://propertease.app/payment/success";
        private const string CancelUrl  = "https://propertease.app/payment/cancel";

        private readonly UnitOfWork _unitOfWork;
        private readonly IPropertyReservationService _reservationService;
        private readonly IRabbitMQPublisher _publisher;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<PaymentService> _logger;

        private readonly string _payPalClientId;
        private readonly string _payPalSecret;
        private readonly string _payPalBaseUrl;
        private readonly bool _isPayPalSandbox;

        public PaymentService(
            IUnitOfWork unitOfWork,
            IPropertyReservationService reservationService,
            IConfiguration configuration,
            IRabbitMQPublisher publisher,
            IHttpClientFactory httpClientFactory,
            ILogger<PaymentService> logger)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _reservationService = reservationService;
            _publisher = publisher;
            _httpClientFactory = httpClientFactory;
            _logger = logger;

            var mode = configuration["PayPal:Mode"] ?? "sandbox";
            _isPayPalSandbox = mode == "sandbox";
            _payPalBaseUrl = _isPayPalSandbox
                ? "https://api.sandbox.paypal.com"
                : "https://api.paypal.com";
            _payPalClientId = configuration["PayPal:ClientId"] ?? string.Empty;
            _payPalSecret   = configuration["PayPal:Secret"]   ?? string.Empty;
        }

        // ── Public API ────────────────────────────────────────────────────────────

        public PayPalConfigDto GetPayPalConfig() => new PayPalConfigDto
        {
            ClientId    = _payPalClientId,
            SandboxMode = _isPayPalSandbox
        };

        public async Task<(string PaymentId, string ApprovalUrl)> CreatePayPalPaymentAsync(decimal amount)
        {
            if (IsPlaceholderCredentials())
            {
                var fakeId = "sandbox_" + Guid.NewGuid().ToString("N")[..12];
                return (fakeId, $"{ReturnUrl}?paymentId={fakeId}&PayerID=sandbox");
            }

            using var http = _httpClientFactory.CreateClient("PayPal");
            var accessToken = await GetPayPalAccessTokenAsync(http);

            var body = JsonSerializer.Serialize(new
            {
                intent = "sale",
                payer  = new { payment_method = "paypal" },
                redirect_urls = new { return_url = ReturnUrl, cancel_url = CancelUrl },
                transactions  = new[]
                {
                    new
                    {
                        amount      = new { total = amount.ToString("F2"), currency = "USD" },
                        description = "Property reservation payment"
                    }
                }
            });

            var req = new HttpRequestMessage(HttpMethod.Post, $"{_payPalBaseUrl}/v1/payments/payment");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(body, Encoding.UTF8, "application/json");

            var res = await http.SendAsync(req);
            if (!res.IsSuccessStatusCode)
            {
                var err = await res.Content.ReadAsStringAsync();
                throw new BusinessException($"PayPal order creation failed: {err}");
            }

            var data        = JsonSerializer.Deserialize<JsonElement>(await res.Content.ReadAsStringAsync());
            var paymentId   = data.GetProperty("id").GetString()!;
            var approvalUrl = data.GetProperty("links").EnumerateArray()
                .First(l => l.GetProperty("rel").GetString() == "approval_url")
                .GetProperty("href").GetString()!;

            return (paymentId, approvalUrl);
        }

        public async Task<(string PaymentId, string ApprovalUrl)> CreatePayPalPaymentForReservationAsync(int reservationId)
        {
            var db = _unitOfWork.GetDatabaseContext();
            var reservation = await db.PropertyReservations.FindAsync(reservationId)
                ?? throw new NotFoundException("Reservation", reservationId);

            if (reservation.Status != ReservationStatus.Confirmed)
                throw new BusinessException("Plaćanje je moguće samo za potvrđene rezervacije.");

            return await CreatePayPalPaymentAsync((decimal)reservation.TotalPrice);
        }

        public async Task<PropertyReservationDto> CompleteReservationAsync(CompleteReservationPaymentDto dto)
        {
            var db = _unitOfWork.GetDatabaseContext();

            // Idempotency: if this PayPal payment was already processed, return existing reservation
            var existingPayment = await db.Payments
                .FirstOrDefaultAsync(p => p.PayPalPaymentId == dto.PayPalPaymentId && !p.IsDeleted);
            if (existingPayment?.ReservationId != null)
            {
                var existing = await _unitOfWork.PropertyReservationRepository
                    .GetByIdAsync(existingPayment.ReservationId.Value);
                if (existing != null) return existing;
            }

            // Server-side: execute (capture) the approved payment — client never records success
            await ExecutePayPalPaymentAsync(dto.PayPalPaymentId, dto.PayPalPayerId, dto.Amount);

            var payment = new Payment
            {
                ClientId        = dto.ClientId,
                PayPalPaymentId = dto.PayPalPaymentId,
                PayPalPayerId   = dto.PayPalPayerId,
                Amount          = dto.Amount,
                Currency        = "USD",
                Status          = PaymentStatus.Pending,
                Description     = $"Reservation for property {dto.PropertyId}",
                CreatedAt       = DateTime.UtcNow,
                IsDeleted       = false,
            };
            PaymentStateMachine.Transition(payment, PaymentStatus.Completed);

            await _unitOfWork.PaymentRepository.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            var reservationDto = new PropertyReservationDto
            {
                PropertyId           = dto.PropertyId,
                ClientId             = dto.ClientId,
                RenterId             = dto.RenterId,
                NumberOfGuests       = dto.NumberOfGuests,
                DateOfOccupancyStart = dto.DateOfOccupancyStart,
                DateOfOccupancyEnd   = dto.DateOfOccupancyEnd,
                NumberOfDays         = dto.NumberOfDays,
                NumberOfMonths       = dto.NumberOfMonths,
                TotalPrice           = dto.TotalPrice,
                IsMonthly            = dto.IsMonthly,
                IsDaily              = dto.IsDaily,
                Description          = dto.Description,
                CreatedAt            = DateTime.UtcNow,
            };

            var created = await _reservationService.AddAsync(reservationDto);

            payment.ReservationId = created.Id;
            _unitOfWork.PaymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();

            // Payment already captured — promote from Pending to Confirmed immediately
            var created2 = await _reservationService.ConfirmReservationAsync(created.Id, dto.ClientId);

            try
            {
                var prop = await db.Properties
                    .AsNoTracking()
                    .Where(p => p.Id == dto.PropertyId && !p.IsDeleted)
                    .Select(p => new { p.Name })
                    .FirstOrDefaultAsync();

                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == dto.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = dto.ClientId,
                    ReservationId     = created2.Id,
                    Title             = "Plaćanje uspješno",
                    Message           = $"Plaćanje za rezervaciju \"{created2.ReservationNumber}\" je uspješno obrađeno.",
                    ReservationNumber = created2.ReservationNumber,
                    PropertyName      = prop?.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = dto.RenterId,
                    ReservationId     = created2.Id,
                    Title             = "Plaćanje primljeno",
                    Message           = $"Plaćanje za rezervaciju \"{created2.ReservationNumber}\" je uspješno primljeno.",
                    ReservationNumber = created2.ReservationNumber,
                    PropertyName      = prop?.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish payment notifications for reservation {Id}", created2.Id);
            }

            return created2;
        }

        public async Task<PropertyReservationDto> PayForReservationAsync(PayForReservationDto dto, int callerId)
        {
            var db = _unitOfWork.GetDatabaseContext();

            var reservation = await db.PropertyReservations.FindAsync(dto.ReservationId)
                ?? throw new NotFoundException("Reservation", dto.ReservationId);

            if (reservation.Status != ReservationStatus.Confirmed)
                throw new BusinessException("Plaćanje je moguće samo za potvrđene rezervacije.");

            if (reservation.ClientId != callerId)
                throw new BusinessException("Nije moguće platiti rezervaciju drugog korisnika.");

            // Idempotency: if this PayPal payment was already processed, return existing reservation
            var existingPayment = await db.Payments
                .FirstOrDefaultAsync(p => p.PayPalPaymentId == dto.PayPalPaymentId && !p.IsDeleted);
            if (existingPayment?.ReservationId == dto.ReservationId)
                return await _unitOfWork.PropertyReservationRepository.GetByIdAsync(dto.ReservationId);

            // Also guard against double-payment for the same reservation
            var alreadyPaid = await db.Payments
                .AnyAsync(p => p.ReservationId == dto.ReservationId
                               && p.Status == PaymentStatus.Completed
                               && !p.IsDeleted);
            if (alreadyPaid)
                throw new BusinessException("Rezervacija je već plaćena.");

            await ExecutePayPalPaymentAsync(dto.PayPalPaymentId, dto.PayPalPayerId, reservation.TotalPrice);

            var payment = new Payment
            {
                ClientId        = reservation.ClientId,
                ReservationId   = dto.ReservationId,
                PayPalPaymentId = dto.PayPalPaymentId,
                PayPalPayerId   = dto.PayPalPayerId,
                Amount          = dto.Amount,
                Currency        = "USD",
                Status          = PaymentStatus.Pending,
                Description     = $"Payment for reservation #{reservation.ReservationNumber}",
                CreatedAt       = DateTime.UtcNow,
                IsDeleted       = false,
            };
            PaymentStateMachine.Transition(payment, PaymentStatus.Completed);

            await _unitOfWork.PaymentRepository.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();

            try
            {
                var prop = await db.Properties
                    .AsNoTracking()
                    .Where(p => p.Id == reservation.PropertyId && !p.IsDeleted)
                    .Select(p => new { p.Name })
                    .FirstOrDefaultAsync();

                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == reservation.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = reservation.ClientId,
                    ReservationId     = reservation.Id,
                    Title             = "Plaćanje uspješno",
                    Message           = $"Plaćanje za rezervaciju \"{reservation.ReservationNumber}\" je uspješno obrađeno.",
                    ReservationNumber = reservation.ReservationNumber,
                    PropertyName      = prop?.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = reservation.RenterId,
                    ReservationId     = reservation.Id,
                    Title             = "Plaćanje primljeno",
                    Message           = $"Plaćanje za rezervaciju \"{reservation.ReservationNumber}\" je uspješno primljeno.",
                    ReservationNumber = reservation.ReservationNumber,
                    PropertyName      = prop?.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish payment notification for reservation {Id}", dto.ReservationId);
            }

            return await _unitOfWork.PropertyReservationRepository.GetByIdAsync(dto.ReservationId);
        }

        public async Task RefundReservationAsync(
            int reservationId,
            bool enforceSevenDayRule,
            int? actorId = null,
            string? reason = null)
        {
            var db = _unitOfWork.GetDatabaseContext();

            var reservation = await db.PropertyReservations.FindAsync(reservationId);
            if (reservation == null || reservation.IsDeleted)
                throw new NotFoundException("Reservation", reservationId);

            if (enforceSevenDayRule)
            {
                var daysUntilCheckIn = (reservation.DateOfOccupancyStart - DateTime.UtcNow).TotalDays;
                if (daysUntilCheckIn < 7)
                    throw new BusinessException(
                        "Cancellation is only allowed more than 7 days before check-in.");
            }

            var finalReason = reason
                ?? (enforceSevenDayRule
                    ? "Otkazano od strane klijenta"
                    : "Otkazano od strane iznajmljivača/admina");

            ReservationStateMachine.Transition(reservation, ReservationStatus.Cancelled, actorId, finalReason);

            var payment = await _unitOfWork.PaymentRepository.GetByReservationIdAsync(reservationId);

            if (payment != null && !string.IsNullOrEmpty(payment.PayPalPaymentId)
                && PaymentStateMachine.CanTransition(payment.Status, PaymentStatus.Refunded))
            {
                try
                {
                    await RefundPayPalPaymentAsync(payment.PayPalPaymentId, payment.Amount);
                }
                catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    // Payment ID not found in PayPal (e.g. seeded/test data) — skip PayPal refund
                    // but still cancel the reservation and mark payment as refunded in the DB.
                    _logger.LogWarning(
                        "PayPal payment {PaymentId} not found (404) — skipping PayPal refund for reservation {ReservationId}.",
                        payment.PayPalPaymentId, reservationId);
                }
                PaymentStateMachine.Transition(payment, PaymentStatus.Refunded);
                _unitOfWork.PaymentRepository.Update(payment);
            }

            db.PropertyReservations.Update(reservation);
            await _unitOfWork.SaveChangesAsync();

            await _reservationService.SyncPropertyAvailabilityAsync(reservation.PropertyId);

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

                var propertyName      = property?.Name ?? string.Empty;
                var reservationNumber = reservation.ReservationNumber ?? $"#{reservation.Id:D4}";

                _publisher.Publish(new
                {
                    ReservationId      = reservation.Id,
                    ReservationNumber  = reservationNumber,
                    PropertyName       = propertyName,
                    CancellationReason = reservation.CancellationReason,
                    CheckIn            = reservation.DateOfOccupancyStart,
                    CheckOut           = reservation.DateOfOccupancyEnd,
                    TotalPrice         = (decimal)(payment?.Amount ?? 0),
                    PropertyPhotoUrl   = photoUrl,
                    ClientUserId       = reservation.ClientId,
                    ClientEmail        = client?.Email ?? string.Empty,
                    ClientFullName     = $"{client?.Person?.FirstName} {client?.Person?.LastName}".Trim(),
                    RenterUserId       = reservation.RenterId,
                    RenterEmail        = renter?.Email ?? string.Empty,
                    RenterFullName     = $"{renter?.Person?.FirstName} {renter?.Person?.LastName}".Trim(),
                }, "reservation.cancelled");

                if (payment?.Status == PaymentStatus.Refunded)
                {
                    _publisher.Publish(new ReservationNotificationMessage
                    {
                        UserId            = reservation.ClientId,
                        ReservationId     = reservation.Id,
                        Title             = "Povrat sredstava",
                        Message           = $"Povrat sredstava za rezervaciju \"{reservationNumber}\" je uspješno obrađen.",
                        ReservationNumber = reservationNumber,
                        PropertyName      = propertyName,
                        PropertyPhotoUrl  = photoUrl
                    }, "reservation.notification");
                }
            }
            catch
            {
                // messaging failure must not roll back the refund
            }
        }

        // ── Private helpers ───────────────────────────────────────────────────────

        private bool IsPlaceholderCredentials()
            => string.IsNullOrEmpty(_payPalClientId) || _payPalClientId.StartsWith("REPLACE") ||
               string.IsNullOrEmpty(_payPalSecret)   || _payPalSecret.StartsWith("REPLACE");

        private async Task<string> GetPayPalAccessTokenAsync(HttpClient http)
        {
            var credentials = Convert.ToBase64String(
                Encoding.UTF8.GetBytes($"{_payPalClientId}:{_payPalSecret}"));

            var req = new HttpRequestMessage(HttpMethod.Post, $"{_payPalBaseUrl}/v1/oauth2/token");
            req.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);
            req.Content = new StringContent(
                "grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

            var res = await http.SendAsync(req);
            res.EnsureSuccessStatusCode();
            var data = JsonSerializer.Deserialize<JsonElement>(await res.Content.ReadAsStringAsync());
            return data.GetProperty("access_token").GetString()!;
        }

        private async Task ExecutePayPalPaymentAsync(string paymentId, string payerId, double expectedAmount)
        {
            if (IsPlaceholderCredentials()) return;

            using var http = _httpClientFactory.CreateClient("PayPal");
            var accessToken = await GetPayPalAccessTokenAsync(http);

            var body = JsonSerializer.Serialize(new { payer_id = payerId });
            var req  = new HttpRequestMessage(
                HttpMethod.Post, $"{_payPalBaseUrl}/v1/payments/payment/{paymentId}/execute");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(body, Encoding.UTF8, "application/json");

            var res = await http.SendAsync(req);
            if (!res.IsSuccessStatusCode)
            {
                var err = await res.Content.ReadAsStringAsync();
                throw new BusinessException($"PayPal execution failed: {err}");
            }

            var data  = JsonSerializer.Deserialize<JsonElement>(await res.Content.ReadAsStringAsync());
            var state = data.GetProperty("state").GetString();
            if (state != "approved")
                throw new BusinessException($"PayPal payment state after execution is '{state}'.");

            var capturedTotal = data
                .GetProperty("transactions")[0]
                .GetProperty("amount")
                .GetProperty("total")
                .GetString();
            if (capturedTotal != null && double.TryParse(capturedTotal,
                    System.Globalization.NumberStyles.Any,
                    System.Globalization.CultureInfo.InvariantCulture, out var actual)
                && Math.Abs(actual - expectedAmount) > 0.01)
            {
                throw new BusinessException(
                    $"PayPal amount mismatch: expected {expectedAmount:F2}, captured {capturedTotal}.");
            }
        }

        private async Task RefundPayPalPaymentAsync(string paymentId, double amount)
        {
            if (IsPlaceholderCredentials()) return;

            using var http = _httpClientFactory.CreateClient("PayPal");
            var accessToken = await GetPayPalAccessTokenAsync(http);

            var paymentReq = new HttpRequestMessage(
                HttpMethod.Get, $"{_payPalBaseUrl}/v1/payments/payment/{paymentId}");
            paymentReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
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

            var refundBody = JsonSerializer.Serialize(new
            {
                amount = new { total = amount.ToString("F2"), currency = "USD" }
            });
            var refundReq = new HttpRequestMessage(
                HttpMethod.Post, $"{_payPalBaseUrl}/v1/payments/sale/{saleId}/refund");
            refundReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            refundReq.Content = new StringContent(refundBody, Encoding.UTF8, "application/json");

            var refundRes = await http.SendAsync(refundReq);
            if (!refundRes.IsSuccessStatusCode)
            {
                var err = await refundRes.Content.ReadAsStringAsync();
                throw new BusinessException($"PayPal refund failed: {err}");
            }
        }
    }
}
