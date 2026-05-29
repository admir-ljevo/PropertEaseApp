using AutoMapper;
using Microsoft.EntityFrameworkCore;
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

        public async Task<(List<CountryDto> items, int totalCount)> GetFilteredAsync(string? search, int page, int pageSize)
        {
            var query = DatabaseContext.Countries.Where(c => !c.IsDeleted);
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(c => c.Name != null && c.Name.Contains(search));
            var totalCount = await query.CountAsync();
            var items = await ProjectToListAsync<CountryDto>(query.OrderBy(c => c.Name).Skip((page - 1) * pageSize).Take(pageSize));
            return (items, totalCount);
        }
    }
}
