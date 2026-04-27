using Microsoft.Extensions.Caching.Memory;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Services.PropertyTypeService
{
    public class PropertyTypeService : IPropertyTypeService
    {
        private const string CacheKey = "ref:property_types:all";
        private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(1);

        private readonly UnitOfWork _unitOfWork;
        private readonly IMemoryCache _cache;

        public PropertyTypeService(IUnitOfWork unitOfWork, IMemoryCache cache)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _cache = cache;
        }

        public async Task<List<PropertyTypeDto>> GetAllAsync()
        {
            if (_cache.TryGetValue(CacheKey, out List<PropertyTypeDto>? cached))
                return cached!;

            var result = await _unitOfWork.PropertyTypeRepository.GetAllAsync();
            _cache.Set(CacheKey, result, CacheTtl);
            return result;
        }

        public async Task<PropertyTypeDto> GetByIdAsync(int id)
            => await _unitOfWork.PropertyTypeRepository.GetByIdAsync(id);

        public async Task<List<PropertyTypeDto>> GetByNameAsync(string name)
            => await _unitOfWork.PropertyTypeRepository.GetByName(name);

        public async Task<PropertyTypeDto> AddAsync(PropertyTypeDto entityDto)
        {
            await _unitOfWork.PropertyTypeRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entityDto;
        }

        public void Update(PropertyTypeDto entity)
        {
            _unitOfWork.PropertyTypeRepository.Update(entity);
            _unitOfWork.SaveChanges();
            _cache.Remove(CacheKey);
        }

        public async Task<PropertyTypeDto> UpdateAsync(PropertyTypeDto entity)
        {
            _unitOfWork.PropertyTypeRepository.Update(entity);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
            return entity;
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var db = _unitOfWork.GetDatabaseContext();

            if (db.Properties.Any(p => p.PropertyTypeId == id && !p.IsDeleted))
                throw new InvalidOperationException("Cannot delete a property type that has properties assigned to it.");

            await _unitOfWork.PropertyTypeRepository.RemoveByIdAsync(id, isSoft);
            await _unitOfWork.SaveChangesAsync();
            _cache.Remove(CacheKey);
        }
    }
}
