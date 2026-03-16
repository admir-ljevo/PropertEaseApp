using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Payment;
using PropertEase.Services.Services.PaymentService;

namespace PropertEase.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpGet("Config")]
        [AllowAnonymous]
        public IActionResult GetConfig()
        {
            return Ok(_paymentService.GetPayPalConfig());
        }

        [HttpPost("CompleteReservation")]
        public async Task<IActionResult> CompleteReservation([FromBody] CompleteReservationPaymentDto dto)
        {
            try
            {
                var reservation = await _paymentService.CompleteReservationAsync(dto);
                return Ok(reservation);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        /// <summary>
        /// Refund reservation payment and deactivate it.
        /// Pass isClient=true to enforce the 7-day cancellation rule.
        /// </summary>
        [HttpPost("RefundReservation/{reservationId}")]
        public async Task<IActionResult> RefundReservation(int reservationId,
            [FromQuery] bool isClient = false)
        {
            try
            {
                await _paymentService.RefundReservationAsync(reservationId,
                    enforceSevenDayRule: isClient);
                return Ok(new { message = "Rezervacija otkazana i refund je izvršen." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }
    }
}
