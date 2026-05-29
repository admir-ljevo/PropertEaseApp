using PropertEase.Core.Dto.City;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.CityService
{
    public interface ICityService: IBaseService<CityDto>
    {
        public Task<List<CityDto>> GetByNameAsync(string name);
        Task<(List<CityDto> items, int totalCount)> GetFilteredAsync(string? search, int page, int pageSize);
    }
}
