using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.Services.ReservationNotificationService;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReservationNotificationController : ControllerBase
    {
        private readonly IReservationNotificationService _service;

        public ReservationNotificationController(IReservationNotificationService service)
        {
            _service = service;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(int userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var result = await _service.GetByUserAsync(userId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("user/{userId}/unseen-count")]
        public async Task<IActionResult> GetUnseenCount(int userId)
        {
            var count = await _service.GetUnseenCountAsync(userId);
            return Ok(count);
        }

        [HttpPut("mark-seen/{userId}")]
        public async Task<IActionResult> MarkAllSeen(int userId)
        {
            await _service.MarkAllSeenAsync(userId);
            return Ok();
        }
    }
}
