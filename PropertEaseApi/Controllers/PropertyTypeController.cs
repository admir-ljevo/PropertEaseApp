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
        public PropertyTypeController(IPropertyTypeService baseService, IMapper mapper) : base(baseService, mapper)
        {
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
            try
            {
                var all = await BaseService.GetAllAsync();
                var filtered = string.IsNullOrWhiteSpace(search)
                    ? all
                    : all.Where(x => x.Name != null && x.Name.Contains(search, StringComparison.OrdinalIgnoreCase)).ToList();
                var totalCount = filtered.Count;
                var items = filtered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { items, totalCount });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }
    }
}
