using Microsoft.Extensions.Caching.Memory;
using PropertEase.Core.Dto.City;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Services.CityService
{
    public class CityService : ICityService
    {
        private const string CacheKey = "ref:cities:all";
        private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(1);

        private readonly UnitOfWork _unitOfWork;
        private readonly IMemoryCache _cache;

        public CityService(IUnitOfWork unitOfWork, IMemoryCache cache)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _cache = cache;
        }

        public async Task<List<CityDto>> GetAllAsync()
        {
            if (_cache.TryGetValue(CacheKey, out List<CityDto>? cached))
                return cached!;

            var result = await _unitOfWork.CityRepository.GetAllAsync();
            _cache.Set(CacheKey, result, CacheTtl);
            return result;
        }

        public async Task<CityDto> GetByIdAsync(int id)
            => await _unitOfWork.CityRepository.GetByIdAsync(id);

        public async Task<List<CityDto>> GetByNameAsync(string name)
            => await _unitOfWork.CityRepository.GetByName(name);

        public async Task<CityDto> AddAsync(CityDto entityDto)
        {
            await _unitOfWork.CityRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entityDto;
        }

        public void Update(CityDto entity)
        {
            _unitOfWork.CityRepository.Update(entity);
            _unitOfWork.SaveChanges();
            _cache.Remove(CacheKey);
        }

        public async Task<CityDto> UpdateAsync(CityDto entity)
        {
            _unitOfWork.CityRepository.Update(entity);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entity;
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var db = _unitOfWork.GetDatabaseContext();

            if (db.Properties.Any(p => p.CityId == id && !p.IsDeleted))
                throw new InvalidOperationException("Cannot delete a city that has properties assigned to it.");

            if (db.Persons.Any(p => (p.PlaceOfResidenceId == id || p.BirthPlaceId == id) && !p.IsDeleted))
                throw new InvalidOperationException("Cannot delete a city that is set as a place of residence or birth place for one or more users.");

            await _unitOfWork.CityRepository.RemoveByIdAsync(id, isSoft);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
        }
    }
}
