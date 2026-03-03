using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.Filters;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.PropertyRatingService;
using MobiFon.Services.Services.PropertyService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace MobiFon.Controllers
{
    public class PropertyRatingsController : BaseController<PropertyRatingDto, PropertyRatingUpsertDto, PropertyRatingUpsertDto, BaseSearchObject>
    {
       private readonly IPropertyRatingService propertyRatingService;
        public PropertyRatingsController(IPropertyRatingService baseService, IMapper mapper) : base(baseService, mapper)
        {
            propertyRatingService = baseService;
        }

        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] RatingsFilter filter)
        {
            try
            {
                var ratings = await propertyRatingService.GetFiltered(filter);
                return Ok(ratings);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

    }
}
