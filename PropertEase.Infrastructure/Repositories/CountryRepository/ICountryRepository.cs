using PropertEase.Core.Dto.Country;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.CountryRepository
{
    public interface ICountryRepository : IBaseRepository<Country, int>
    {
        Task<List<CountryDto>> GetAllAsync();
        Task<CountryDto> GetByIdAsync(int id);
    }
}
