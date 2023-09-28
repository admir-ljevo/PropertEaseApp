using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.PropertyReservationService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace MobiFon.Controllers
{
    public class PropertyReservationController : BaseController<PropertyReservationDto, PropertyReservationUpsertDto, PropertyReservationUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyReservationService propertyReservationService;
        public PropertyReservationController(IPropertyReservationService baseService, IMapper mapper): base(baseService, mapper)
        {
            propertyReservationService = baseService;
        }
        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyReservationFilter filter)
        {
            try
            {
                var propertyReservations = await propertyReservationService.GetFiltered(filter);
                return Ok(propertyReservations);
            }
            catch (Exception ex)
            {

                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }
    }
}
