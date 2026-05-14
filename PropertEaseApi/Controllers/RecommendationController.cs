using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.Recommendations;
using System.Security.Claims;

namespace PropertEase.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class RecommendationController : ControllerBase
{
    private readonly IRecommendationEngine _engine;

    public RecommendationController(IRecommendationEngine engine)
    {
        _engine = engine;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetRecommendations()
    {
        var userId = int.TryParse(User.FindFirstValue("Id"), out var id) ? id : 0;
        var propertyIds = await _engine.GetRecommendationsAsync(userId);
        return Ok(propertyIds);
    }
}
