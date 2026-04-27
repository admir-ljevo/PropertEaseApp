using Microsoft.Extensions.Caching.Memory;
using PropertEase.Core.Dto.Country;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Services.CountryService
{
    public class CountryService : ICountryService
    {
        private const string CacheKey = "ref:countries:all";
        private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(1);

        private readonly UnitOfWork _unitOfWork;
        private readonly IMemoryCache _cache;

        public CountryService(IUnitOfWork unitOfWork, IMemoryCache cache)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _cache = cache;
        }

        public async Task<List<CountryDto>> GetAllAsync()
        {
            if (_cache.TryGetValue(CacheKey, out List<CountryDto>? cached))
                return cached!;

            var result = await _unitOfWork.CountryRepository.GetAllAsync();
            _cache.Set(CacheKey, result, CacheTtl);
            return result;
        }

        public async Task<CountryDto> GetByIdAsync(int id)
            => await _unitOfWork.CountryRepository.GetByIdAsync(id);

        public async Task<CountryDto> AddAsync(CountryDto entityDto)
        {
            await _unitOfWork.CountryRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entityDto;
        }

        public void Update(CountryDto entity)
        {
            _unitOfWork.CountryRepository.Update(entity);
            _unitOfWork.SaveChanges();
            _cache.Remove(CacheKey);
        }

        public async Task<CountryDto> UpdateAsync(CountryDto entity)
        {
            _unitOfWork.CountryRepository.Update(entity);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entity;
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var hasCities = _unitOfWork.GetDatabaseContext().Cities
                .Any(c => c.CountryId == id && !c.IsDeleted);

            if (hasCities)
                throw new InvalidOperationException("Cannot delete a country that has cities assigned to it.");

            await _unitOfWork.CountryRepository.RemoveByIdAsync(id, isSoft);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
        }
    }
}
