using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Controllers;
using PropertEase.Core.Dto.City;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.CityService;

namespace PropertEase.Controllers
{
    public class CityController : BaseController<CityDto, CityUpsertDto, CityUpsertDto, BaseSearchObject>
    {
        private readonly ICityService cityService;
        public CityController(ICityService baseService, IMapper mapper) : base(baseService, mapper)
        {
            cityService = baseService;
        }

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
