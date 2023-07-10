using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Filters;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.PropertyService;
using Swashbuckle.AspNetCore.Annotations;

namespace MobiFon.Controllers
{

    public class PropertyController : BaseController<PropertyDto, PropertyUpsertDto, PropertyUpsertDto, BaseSearchObject>
    {
       private readonly IPropertyService propertyService;
        public PropertyController(IPropertyService baseService, IMapper mapper) : base(baseService, mapper)
        {
            propertyService = baseService;
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

    }
}
