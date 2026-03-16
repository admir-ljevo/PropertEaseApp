using AutoMapper;
using PropertEase.Core.Dto.Country;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.CountryRepository
{
    public class CountryRepository : BaseRepository<Country, int>, ICountryRepository
    {
        public CountryRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<List<CountryDto>> GetAllAsync()
        {
            return await ProjectToListAsync<CountryDto>(DatabaseContext.Countries.Where(c => !c.IsDeleted));
        }

        public async Task<CountryDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<CountryDto>(DatabaseContext.Countries.Where(c => c.Id == id && !c.IsDeleted));
        }
    }
}
