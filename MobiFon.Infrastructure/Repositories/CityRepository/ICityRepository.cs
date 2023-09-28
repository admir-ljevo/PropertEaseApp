using MobiFon.Core.Dto.City;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.CityRepository
{
    public interface ICityRepository: IBaseRepository<City, int>
    {
        new Task<List<CityDto>> GetAllAsync();
        Task<List<CityDto>> GetByName(string name);
        Task<CityDto> GetByIdAsync(int id);
        Task<List<CityDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset) => throw new NotImplementedException();    
    }
}
