using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Services.Recommendations;

namespace MobiFon.Controllers;

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

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetRecommendations(int userId)
    {
        var propertyIds = await _engine.GetRecommendationsAsync(userId);
        return Ok(propertyIds);
    }
}
