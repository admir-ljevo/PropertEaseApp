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

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(int userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!IsAuthorizedForUser(userId)) return Forbid();
            pageSize = Paging.Clamp(pageSize);
            var result = await _service.GetByUserAsync(userId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("user/{userId}/unseen-count")]
        public async Task<IActionResult> GetUnseenCount(int userId)
        {
            if (!IsAuthorizedForUser(userId)) return Forbid();
            var count = await _service.GetUnseenCountAsync(userId);
            return Ok(count);
        }

        [HttpPut("mark-seen/{userId}")]
        public async Task<IActionResult> MarkAllSeen(int userId)
        {
            if (!IsAuthorizedForUser(userId)) return Forbid();
            await _service.MarkAllSeenAsync(userId);
            return Ok();
        }

        [HttpPut("mark-seen-single/{id}")]
        public async Task<IActionResult> MarkSingleSeen(int id)
        {
            await _service.MarkSeenAsync(id);
            return Ok();
        }

        private bool IsAuthorizedForUser(int userId)
        {
            if (User.IsInRole(AppRoles.Admin)) return true;
            var tokenUserId = User.FindFirstValue("Id");
            return tokenUserId != null && tokenUserId == userId.ToString();
        }
    }
}
