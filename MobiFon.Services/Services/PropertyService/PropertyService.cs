using MobiFon.Core.Dto.Property;
using MobiFon.Core.Filters;
using MobiFon.Infrastructure.UnitOfWork;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PropertyService
{
    public class PropertyService : IPropertyService
    {
        private readonly UnitOfWork unitOfWork;
        public PropertyService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<PropertyDto> AddAsync(PropertyDto entityDto)
        {
            await unitOfWork.PropertyRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;   
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

        public async Task<List<PropertyDto>> GetFilteredData(PropertyFilter filter)
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
    }
}
