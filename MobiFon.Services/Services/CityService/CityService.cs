using MobiFon.Core.Dto.City;
using MobiFon.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.CityService
{
    public class CityService : ICityService
    {
        private readonly UnitOfWork unitOfWork;
        public CityService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }
        public async Task<CityDto> AddAsync(CityDto entityDto)
        {
            await unitOfWork.CityRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<CityDto>> GetAllAsync()
        {
            return await unitOfWork.CityRepository.GetAllAsync();
        }

        public async Task<CityDto> GetByIdAsync(int id)
        {
            return await unitOfWork.CityRepository.GetByIdAsync(id);
        }

        public async Task<List<CityDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.CityRepository.GetByName(name);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.CityRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(CityDto entity)
        {
            unitOfWork.CityRepository.Update(entity);
            unitOfWork.SaveChanges();
        }
        public async Task<CityDto> UpdateAsync(CityDto entity)
        {
            unitOfWork.CityRepository.Update(entity);
            await unitOfWork.SaveChangesAsync();
            return entity;
        }
    }
}
