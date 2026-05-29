using PropertEase.Core.Dto.Country;
using PropertEase.Services.Services.BaseService;

namespace PropertEase.Services.Services.CountryService
{
    public interface ICountryService : IBaseService<CountryDto>
    {
        Task<(List<CountryDto> items, int totalCount)> GetFilteredAsync(string? search, int page, int pageSize);
    }
}
