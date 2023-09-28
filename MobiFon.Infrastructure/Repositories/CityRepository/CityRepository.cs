using AutoMapper;
using MobiFon.Core.Dto.City;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.CityRepository
{
    public class CityRepository : BaseRepository<City, int>, ICityRepository
    {
        public CityRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }
        public async Task<List<CityDto>> GetAllAsync()
        {
            return await ProjectToListAsync<CityDto>(DatabaseContext.Cities.Where(c => !c.IsDeleted));
        }
        public async Task<CityDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<CityDto>(DatabaseContext.Cities.Where(c => c.Id == id && !c.IsDeleted));
        }

        public async Task<List<CityDto>> GetByName(string name)
        {
            return await ProjectToListAsync<CityDto>(DatabaseContext.Cities.Where(c => !c.IsDeleted && c.Name == name));
        }


    }
}
