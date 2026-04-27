using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.PropertyRating;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.PropertyRatingService;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
{
    public class PropertyRatingsController : BaseController<PropertyRatingDto, PropertyRatingUpsertDto, PropertyRatingUpsertDto, BaseSearchObject>
    {
       private readonly IPropertyRatingService propertyRatingService;
        public PropertyRatingsController(IPropertyRatingService baseService, IMapper mapper) : base(baseService, mapper)
        {
            propertyRatingService = baseService;
        }

        [NonAction] public override Task<List<PropertyRatingDto>> Get([FromQuery] int page = 1, [FromQuery] int pageSize = 20) => throw new NotSupportedException();
        [NonAction] public override Task<PropertyRatingDto> Get(int id) => throw new NotSupportedException();
        [NonAction] public override Task<PropertyRatingDto> Put(int id, PropertyRatingUpsertDto updateEntity) => throw new NotSupportedException();
        [NonAction] public override Task<IActionResult> Delete(int id) => throw new NotSupportedException();

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
