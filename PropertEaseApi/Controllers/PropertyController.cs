using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Services.Services.PropertyReservationService;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
{

    public class PropertyController : BaseController<PropertyDto, PropertyUpsertDto, PropertyUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyService propertyService;
        private readonly IPropertyReservationService _reservationService;

        public PropertyController(IPropertyService baseService, IMapper mapper, IPropertyReservationService reservationService)
            : base(baseService, mapper)
        {
            propertyService = baseService;
            _reservationService = reservationService;
        }

        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyFilter filter)
        {
            try
            {
                var properties = await propertyService.GetFilteredData(filter);
                return Ok(properties);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            var upcomingCount = await _reservationService.GetUpcomingCountByPropertyAsync(id);
            if (upcomingCount > 0)
                return Conflict(new { upcomingCount });
            await propertyService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpDelete("{id}/force")]
        [SwaggerOperation(OperationId = "ForceDeleteProperty")]
        public async Task<IActionResult> ForceDelete(int id)
        {
            await propertyService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("{id}/Recommendations")]
        [SwaggerOperation(OperationId = "GetRecommendations")]
        public async Task<IActionResult> GetRecommendations(int id)
        {
            try
            {
                var recommendations = await propertyService.GetRecommendedPropertiesAsync(id);
                return Ok(recommendations);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

    }
}
