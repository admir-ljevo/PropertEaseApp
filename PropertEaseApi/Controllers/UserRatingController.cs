using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.UserRatingService;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserRatingController : BaseController<UserRatingDto, UserRatingUpsertDto, UserRatingUpsertDto, BaseSearchObject>
    {
        private readonly IUserRatingService _userRatingService;

        public UserRatingController(IUserRatingService userRatingService, IMapper mapper)
            : base(userRatingService, mapper)
        {
            _userRatingService = userRatingService;
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] UserRatingFilter filter)
        {
            var result = await _userRatingService.GetFiltered(filter);
            return Ok(result);
        }

        [HttpGet("GetAverageRating/{renterId}")]
        public async Task<IActionResult> GetAverageRating(int renterId)
        {
            var avg = await _userRatingService.GetAverageRating(renterId);
            return Ok(avg);
        }
    }
}
