using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.PropertyTypeService;
using PropertEase.Shared.Constants;

namespace PropertEase.Controllers
{
    public class PropertyTypeController : BaseController<PropertyTypeDto, PropertyTypeUpsertDto, PropertyTypeUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyTypeService _propertyTypeService;
        public PropertyTypeController(IPropertyTypeService baseService, IMapper mapper) : base(baseService, mapper)
        {
            _propertyTypeService = baseService;
        }

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<PropertyTypeDto> Post(PropertyTypeUpsertDto insertEntity) => base.Post(insertEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<PropertyTypeDto> Put(int id, PropertyTypeUpsertDto updateEntity) => base.Put(id, updateEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<IActionResult> Delete(int id) => base.Delete(id);

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var (items, totalCount) = await _propertyTypeService.GetFilteredAsync(search, page, pageSize);
            return Ok(new { items, totalCount });
        }
    }
}
