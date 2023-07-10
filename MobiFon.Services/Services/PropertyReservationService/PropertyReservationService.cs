﻿using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Infrastructure.UnitOfWork;

namespace MobiFon.Services.Services.PropertyReservationService
{
    public class PropertyReservationService : IPropertyReservationService
    {
        private readonly ILogger<PropertyReservationService> logger;
        private readonly UnitOfWork unitOfWork;

        public PropertyReservationService(IUnitOfWork unitOfWork, ILogger<PropertyReservationService> logger)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
            this.logger = logger;
        }

        public async Task<PropertyReservationDto> AddAsync(PropertyReservationDto entityDto)
        {
            entityDto.IsActive = true;
            await unitOfWork.PropertyReservationRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyReservationRepository.GetAllAsync();
        }

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
        {
            logger.LogInformation("Runje");
            return await unitOfWork.PropertyReservationRepository.GetByIdAsync(id);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.PropertyReservationRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(PropertyReservationDto entity)
        {
            unitOfWork.PropertyReservationRepository.Update(entity);
            unitOfWork.SaveChanges();
        }

        public async Task<PropertyReservationDto> UpdateAsync(PropertyReservationDto property)
        {
            unitOfWork.PropertyRatingRepository.Update(property);
            await unitOfWork.SaveChangesAsync();
            return property;

        }

    }
}
