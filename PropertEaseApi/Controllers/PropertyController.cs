using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Shared.Constants;
using Swashbuckle.AspNetCore.Annotations;
using System.Security.Claims;

namespace PropertEase.Controllers
{

    public class PropertyController : BaseController<PropertyDto, PropertyUpsertDto, PropertyUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyService propertyService;

        public PropertyController(IPropertyService baseService, IMapper mapper)
            : base(baseService, mapper)
        {
            propertyService = baseService;
        }

        [AllowAnonymous]
        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyFilter filter)
        {
            var properties = await propertyService.GetFilteredData(filter);
            return Ok(properties);
        }

        [Authorize(Roles = AppRoles.Admin + "," + AppRoles.Renter)]
        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            if (!User.IsInRole(AppRoles.Admin))
            {
                var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
                var property = await propertyService.GetByIdAsync(id);
                if (property == null || property.ApplicationUserId != callerId)
                    return Forbid();
            }

            await propertyService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("{id}/Recommendations")]
        [SwaggerOperation(OperationId = "GetRecommendations")]
        public async Task<IActionResult> GetRecommendations(int id)
        {
            var recommendations = await propertyService.GetRecommendedPropertiesAsync(id);
            return Ok(recommendations);
        }

    }
}
