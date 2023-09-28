﻿using AutoMapper;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.Entities;
using MobiFon.Core.SearchObjects;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyReservationRepository
{
    public class PropertyReservationRepository : BaseRepository<PropertyReservation, int>, IPropertyReservationRepository
    {
        public PropertyReservationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => pr.Id == id && !pr.IsDeleted));
        }

        public Task<List<PropertyReservationDto>> GetByNameAsync(string name)
        {
            throw new NotImplementedException();
        }

        public async Task<List<PropertyReservationDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset)
        {
            return await ProjectToListAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => !pr.IsDeleted).Skip(offset).Take(pageSize));
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => !pr.IsDeleted));
        }
        public async Task<List<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter)
        {
            var reservations = await ProjectToListAsync<PropertyReservationDto>(
         DatabaseContext.PropertyReservations
        .Where(pr => (string.IsNullOrEmpty(filter.propertyName) || pr.Property.Name.Contains(filter.propertyName))
                    && (!filter.DateOccupancyStarted.HasValue || pr.DateOfOccupancyStart >= filter.DateOccupancyStarted.Value)
                    && (!filter.DateOccupancyEnded.HasValue || pr.DateOfOccupancyEnd <= filter.DateOccupancyEnded.Value)
                    && (!filter.totalPriceFrom.HasValue || pr.TotalPrice >= filter.totalPriceFrom.Value)
                    && (!filter.totalPriceTo.HasValue || pr.TotalPrice <= filter.totalPriceTo.Value)
                    && (filter.propertyTypeId == 0 || pr.Property.PropertyTypeId == filter.propertyTypeId) &&
                    (!filter.isActive.HasValue || pr.IsActive == filter.isActive.Value )&&(!pr.IsDeleted)
        )
);

            return reservations;

        }

    }
}
