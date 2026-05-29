using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Controllers;
using PropertEase.Core.Dto.Country;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.CountryService;
using PropertEase.Shared.Constants;

namespace PropertEaseApi.Controllers
{
    public class CountryController : BaseController<CountryDto, CountryUpsertDto, CountryUpsertDto, BaseSearchObject>
    {
        private readonly ICountryService _countryService;
        public CountryController(ICountryService baseService, IMapper mapper) : base(baseService, mapper)
        {
            _countryService = baseService;
        }

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<CountryDto> Post(CountryUpsertDto insertEntity) => base.Post(insertEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<CountryDto> Put(int id, CountryUpsertDto updateEntity) => base.Put(id, updateEntity);

        [Authorize(Roles = AppRoles.Admin)]
        public override Task<IActionResult> Delete(int id) => base.Delete(id);

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var (items, totalCount) = await _countryService.GetFilteredAsync(search, page, pageSize);
            return Ok(new { items, totalCount });
        }
    }
}
