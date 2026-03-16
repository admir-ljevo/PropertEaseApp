using PropertEase.Core.Dto.Property;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Services.Recommendations;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyService
{
    public class PropertyService : IPropertyService
    {
        private readonly UnitOfWork unitOfWork;
        private readonly IRecommendationEngine _recommendationEngine;

        public PropertyService(IUnitOfWork unitOfWork, IRecommendationEngine recommendationEngine)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
            _recommendationEngine = recommendationEngine;
        }

        public async Task<PropertyDto> AddAsync(PropertyDto entityDto)
        {
            var insertedDto = await unitOfWork.PropertyRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return insertedDto;
        }

        public async Task<List<PropertyDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyRepository.GetAllAsync();   
        }

        public async Task<PropertyDto> GetByIdAsync(int id)
        {
            return await unitOfWork.PropertyRepository.GetByIdAsync(id);
        }

        public async Task<List<PropertyDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.PropertyRepository.GetByName(name);
        }

        public async Task<PropertEase.Core.Dto.PagedResult<PropertyListDto>> GetFilteredData(PropertyFilter filter)
        {
            return await unitOfWork.PropertyRepository.GetFilteredData(filter);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.PropertyRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(PropertyDto entity)
        {
            unitOfWork.PropertyRepository.Update(entity);
            unitOfWork.SaveChanges();
        }
        public async Task<PropertyDto> UpdateAsync(PropertyDto property)
        {
            unitOfWork.PropertyRepository.Update(property);
            await unitOfWork.SaveChangesAsync();
            return property;
        }

        public async Task<List<PropertyRecommendationDto>> GetRecommendedPropertiesAsync(int propertyId)
        {
            var recommendedIds = await _recommendationEngine.GetRecommendationsByPropertyAsync(propertyId);
            if (recommendedIds.Count == 0) return new List<PropertyRecommendationDto>();
            return await unitOfWork.PropertyRepository.GetByIdsAsync(recommendedIds);
        }
    }
}
