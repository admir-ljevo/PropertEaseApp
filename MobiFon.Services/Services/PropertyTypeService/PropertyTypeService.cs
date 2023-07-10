using MobiFon.Core.Dto.PropertyType;
using MobiFon.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PropertyTypeService
{
    public class PropertyTypeService : IPropertyTypeService
    {
        private readonly UnitOfWork unitOfWork;
        public PropertyTypeService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<PropertyTypeDto> AddAsync(PropertyTypeDto entityDto)
        {
            await unitOfWork.PropertyTypeRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<PropertyTypeDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyTypeRepository.GetAllAsync();
        }

        public async Task<PropertyTypeDto> GetByIdAsync(int id)
        {
            return await unitOfWork.PropertyTypeRepository.GetByIdAsync(id);
        }

        public async Task<List<PropertyTypeDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.PropertyTypeRepository.GetByName(name);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.PropertyTypeRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(PropertyTypeDto entity)
        {
            unitOfWork.PropertyTypeRepository.Update(entity);
            unitOfWork.SaveChanges();

        }

        public async Task<PropertyTypeDto> UpdateAsync(PropertyTypeDto entity)
        {
            unitOfWork.PropertyTypeRepository.Update(entity);
            await unitOfWork.SaveChangesAsync();
            return entity;
        }
    }
}
