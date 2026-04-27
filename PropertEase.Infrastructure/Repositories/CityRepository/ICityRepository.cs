using PropertEase.Core.Dto.City;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
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
    }
}
