using MobiFon.Core.Dto.City;
using MobiFon.Services.Services.BaseService;
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
    }
}
