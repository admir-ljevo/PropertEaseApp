using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyRating;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;
using PropertEase.Core.Entities;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyRatingService
{
    public class PropertyRatingService : IPropertyRatingService
    {
        private readonly UnitOfWork unitOfWork;
        private readonly ILogger<PropertyRatingService> logger;

        public PropertyRatingService(IUnitOfWork unitOfWork, ILogger<PropertyRatingService> logger)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
            this.logger = logger;
        }
        public async Task<PropertyRatingDto> AddAsync(PropertyRatingDto entityDto)
        {
            var db = unitOfWork.GetDatabaseContext();

            if (entityDto.ReservationId.HasValue)
            {
                var reservationOk = await db.PropertyReservations
                    .AnyAsync(r => r.Id       == entityDto.ReservationId
                                   && r.PropertyId == entityDto.PropertyId
                                   && r.ClientId   == entityDto.ReviewerId
                                   && r.Status     == ReservationStatus.Completed
                                   && !r.IsDeleted);
                if (!reservationOk)
                    throw new BusinessException("Ocjenu možete dati samo nakon završetka rezervacije.");

                var existing = await db.PropertyRatings
                    .FirstOrDefaultAsync(r => r.ReviewerId    == entityDto.ReviewerId
                                              && r.ReservationId == entityDto.ReservationId
                                              && !r.IsDeleted);
                if (existing != null)
                {
                    existing.Rating      = entityDto.Rating;
                    existing.Description = entityDto.Description;
                    existing.ModifiedAt  = DateTime.UtcNow;
                    await unitOfWork.SaveChangesAsync();
                    entityDto.Id = existing.Id;
                }
                else
                {
                    await unitOfWork.PropertyRatingRepository.AddAsync(entityDto);
                    await unitOfWork.SaveChangesAsync();
                }
            }
            else
            {
                var hasCompleted = await db.PropertyReservations
                    .AnyAsync(r => r.PropertyId == entityDto.PropertyId
                                   && r.ClientId == entityDto.ReviewerId
                                   && r.Status   == ReservationStatus.Completed
                                   && !r.IsDeleted);
                if (!hasCompleted)
                    throw new BusinessException("Ocjenu možete dati samo nakon završetka rezervacije.");

                await unitOfWork.PropertyRatingRepository.AddAsync(entityDto);
                await unitOfWork.SaveChangesAsync();
            }

            var average = await unitOfWork.PropertyRatingRepository.GetAverageRatingAsync(entityDto.PropertyId);
            await unitOfWork.PropertyRepository.UpdateAverageRating(entityDto.PropertyId, average);

            return entityDto;
        }

        public async Task<List<PropertyRatingDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyRatingRepository.GetAllAsync();
        }

        public async Task<PropertyRatingDto> GetByIdAsync(int id)
        {
            return await unitOfWork.PropertyRatingRepository.GetByIdAsync(id);
        }

        public async Task<List<PropertyRatingDto>> GetByPropertyId(int id)
        {
            return await unitOfWork.PropertyRatingRepository.GetByPropertyId(id);
        }

        public async Task<List<PropertyRatingDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.PropertyRatingRepository.GetByName(name);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.PropertyRatingRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public async Task<PropertyRatingDto> UpdateAsync(PropertyRatingDto entity)
        {
            double oldRating = entity.Rating;
            unitOfWork.PropertyRatingRepository.Update(entity);

            await unitOfWork.SaveChangesAsync();
            if (oldRating != entity.Rating)
            {
                var property = await unitOfWork.PropertyRepository.GetByIdAsync(entity.PropertyId);
                var ratingsByProperty = await GetByPropertyId(property.Id);
                property.AverageRating = GetAverageRating(ratingsByProperty);
                unitOfWork.PropertyRepository.Update(property);
                await unitOfWork.SaveChangesAsync();
            }
            return entity;
        }

        public double GetAverageRating(List<PropertyRatingDto> propertyRatings)
        {
            double averageRating = 0;

            foreach (var rating in propertyRatings)
            {
                averageRating += rating.Rating;
            }
            return (averageRating / propertyRatings.Count) * 1.00;
        }

        public async Task<PagedResult<PropertyRatingDto>> GetFiltered(RatingsFilter filter)
        {
            return await unitOfWork.PropertyRatingRepository.GetFiltered(filter);
        }
    }
}
