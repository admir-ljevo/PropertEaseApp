using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Enumerations;
using PropertEase.Infrastructure;
using PropertEase.Services.Services.PaymentService;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly DatabaseContext _db;

        public PaymentController(IPaymentService paymentService, DatabaseContext db)
        {
            _paymentService = paymentService;
            _db = db;
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData(
            [FromQuery] string? search,
            [FromQuery] int? status,
            [FromQuery] DateTime? dateFrom,
            [FromQuery] DateTime? dateTo,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var query = _db.Payments.Where(p => !p.IsDeleted).AsQueryable();

                if (!string.IsNullOrWhiteSpace(search))
                    query = query.Where(p =>
                        (p.PayPalPaymentId != null && p.PayPalPaymentId.Contains(search)) ||
                        (p.Client.UserName != null && p.Client.UserName.Contains(search)) ||
                        (p.Client.Person != null &&
                         (p.Client.Person.FirstName + " " + p.Client.Person.LastName).Contains(search)));

                if (status.HasValue)
                    query = query.Where(p => (int)p.Status == status.Value);

                if (dateFrom.HasValue)
                    query = query.Where(p => p.CreatedAt >= dateFrom.Value);

                if (dateTo.HasValue)
                    query = query.Where(p => p.CreatedAt <= dateTo.Value.AddDays(1));

                var totalCount = await query.CountAsync();

                var items = await query
                    .OrderByDescending(p => p.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(p => new
                    {
                        p.Id,
                        p.ClientId,
                        ClientUsername = p.Client != null ? p.Client.UserName : null,
                        ClientName = p.Client != null && p.Client.Person != null
                            ? p.Client.Person.FirstName + " " + p.Client.Person.LastName
                            : null,
                        p.ReservationId,
                        ReservationNumber = p.Reservation != null ? p.Reservation.ReservationNumber : null,
                        p.PayPalPaymentId,
                        p.Amount,
                        p.Currency,
                        Status = (int)p.Status,
                        StatusName = p.Status.ToString(),
                        p.Description,
                        p.CreatedAt,
                    })
                    .ToListAsync();

                return Ok(new { items, totalCount });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpGet("Config")]
        public IActionResult GetConfig()
        {
            return Ok(_paymentService.GetPayPalConfig());
        }

        [HttpPost("CreatePayPalOrder")]
        public async Task<IActionResult> CreatePayPalOrder([FromQuery] int reservationId)
        {
            var (paymentId, approvalUrl) = await _paymentService.CreatePayPalPaymentForReservationAsync(reservationId);
            return Ok(new { paymentId, approvalUrl });
        }

        [HttpPost("CompleteReservation")]
        public async Task<IActionResult> CompleteReservation([FromBody] CompleteReservationPaymentDto dto)
        {
            dto.ClientId = int.Parse(User.FindFirstValue("Id")!);
            var reservation = await _paymentService.CompleteReservationAsync(dto);
            return Ok(reservation);
        }

        [HttpPost("PayForReservation")]
        public async Task<IActionResult> PayForReservation([FromBody] PayForReservationDto dto)
        {
            var callerId = int.Parse(User.FindFirstValue("Id")!);
            var reservation = await _paymentService.PayForReservationAsync(dto, callerId);
            return Ok(reservation);
        }

        [HttpPost("RefundReservation/{reservationId}")]
        public async Task<IActionResult> RefundReservation(
            int reservationId,
            [FromQuery] bool isClient = false,
            [FromQuery] string? reason = null)
        {
            var actorId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : (int?)null;

            await _paymentService.RefundReservationAsync(
                reservationId,
                enforceSevenDayRule: isClient,
                actorId: actorId,
                reason: reason);

            return Ok(new { message = "Rezervacija otkazana i refund je izvršen." });
        }
    }
}
