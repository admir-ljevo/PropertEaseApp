using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.Services.ReservationNotificationService;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ReservationNotificationController : ControllerBase
    {
        private readonly IReservationNotificationService _service;

        public ReservationNotificationController(IReservationNotificationService service)
        {
            _service = service;
        }

        private int GetCallerId() => int.TryParse(User.FindFirstValue("Id"), out var id) ? id : 0;

        [HttpGet("me")]
        public async Task<IActionResult> GetForMe([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            pageSize = Paging.Clamp(pageSize);
            var result = await _service.GetByUserAsync(GetCallerId(), page, pageSize);
            return Ok(result);
        }

        [HttpGet("me/unseen-count")]
        public async Task<IActionResult> GetUnseenCount()
        {
            var count = await _service.GetUnseenCountAsync(GetCallerId());
            return Ok(count);
        }

        [HttpPut("me/mark-seen")]
        public async Task<IActionResult> MarkAllSeen()
        {
            await _service.MarkAllSeenAsync(GetCallerId());
            return Ok();
        }

        [HttpPut("mark-seen-single/{id}")]
        public async Task<IActionResult> MarkSingleSeen(int id)
        {
            var ownerId = await _service.GetOwnerIdAsync(id);
            if (ownerId == null) return NotFound();
            if (ownerId != GetCallerId()) return Forbid();
            await _service.MarkSeenAsync(id);
            return Ok();
        }
    }
}
