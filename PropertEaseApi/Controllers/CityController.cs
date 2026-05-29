using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Controllers;
using PropertEase.Core.Dto.City;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.CityService;
using PropertEase.Shared.Constants;

namespace PropertEase.Controllers
{
    public class CityController : BaseController<CityDto, CityUpsertDto, CityUpsertDto, BaseSearchObject>
    {
        private readonly ICityService cityService;
        public CityController(ICityService baseService, IMapper mapper) : base(baseService, mapper)
        {
            cityService = baseService;
        }

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<CityDto> Post(CityUpsertDto insertEntity) => base.Post(insertEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<CityDto> Put(int id, CityUpsertDto updateEntity) => base.Put(id, updateEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<IActionResult> Delete(int id) => base.Delete(id);

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var (items, totalCount) = await cityService.GetFilteredAsync(search, page, pageSize);
            return Ok(new { items, totalCount });
        }
    }
}
