using AutoMapper;
using Microsoft.AspNetCore.Authorization;
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
using System.Security.Claims;

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

        [Authorize]
        [HttpPost]
        public override async Task<PropertyRatingDto> Post(PropertyRatingUpsertDto insertEntity)
        {
            insertEntity.ReviewerId = int.TryParse(User.FindFirstValue("Id"), out var id) ? id : 0;
            return await base.Post(insertEntity);
        }

        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] RatingsFilter filter)
        {
            var ratings = await propertyRatingService.GetFiltered(filter);
            return Ok(ratings);
        }

    }
}
