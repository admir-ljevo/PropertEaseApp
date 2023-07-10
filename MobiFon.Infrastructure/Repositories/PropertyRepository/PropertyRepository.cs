using AutoMapper;
using Microsoft.EntityFrameworkCore;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.Entities;
using MobiFon.Core.Filters;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyRepository
{
    public class PropertyRepository : BaseRepository<Property, int>, IPropertyRepository
    {
        public PropertyRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyDto> GetByIdAsync(int id)
        {
            var property = await ProjectToFirstOrDefaultAsync<PropertyDto>(DatabaseContext.Properties.Where(p => p.Id == id));
      //      property.ApplicationUser = await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(DatabaseContext.Persons.Where(p => p.ApplicationUserId == property.ApplicationUserId));

            return property;
        }


        public async Task<List<PropertyDto>> GetFilteredData(PropertyFilter filter)
        {
            var properties = await ProjectToListAsync<PropertyDto>(DatabaseContext.Properties.Where(p => string.IsNullOrEmpty(filter.Name) || p.Name.Contains(filter.Name))
        .Where(p => !filter.PropertyTypeId.HasValue || p.PropertyTypeId == filter.PropertyTypeId.Value)
        .Where(p => !filter.CityId.HasValue || p.CityId == filter.CityId.Value)
        .Where(p => !filter.ApplicationUserId.HasValue || p.ApplicationUserId == filter.ApplicationUserId.Value)
        .Where(p => string.IsNullOrEmpty(filter.Address) || p.Address.Contains(filter.Address))
        .Where(p => string.IsNullOrEmpty(filter.Description) || p.Description.Contains(filter.Description))
        .Where(p => !filter.NumberOfRoomsFrom.HasValue || p.NumberOfRooms >= filter.NumberOfRoomsFrom.Value)
        .Where(p => !filter.NumberOfRoomsTo.HasValue || p.NumberOfRooms <= filter.NumberOfRoomsTo.Value)
        .Where(p => !filter.NumberOfBathroomsFrom.HasValue || p.NumberOfBathrooms >= filter.NumberOfBathroomsFrom.Value)
        .Where(p => !filter.NumberOfBathroomsTo.HasValue || p.NumberOfBathrooms <= filter.NumberOfBathroomsTo.Value)
        .Where(p => !filter.SquareMetersFrom.HasValue || p.SquareMeters >= filter.SquareMetersFrom.Value)
        .Where(p => !filter.SquareMetersTo.HasValue || p.SquareMeters <= filter.SquareMetersTo.Value)
        .Where(p => !filter.CapacityFrom.HasValue || p.Capacity >= filter.CapacityFrom.Value)
        .Where(p => !filter.CapacityTo.HasValue || p.Capacity <= filter.CapacityTo.Value)
        .Where(p => !filter.MonthlyPriceFrom.HasValue || p.MonthlyPrice >= filter.MonthlyPriceFrom.Value)
        .Where(p => !filter.MonthlyPriceTo.HasValue || p.MonthlyPrice <= filter.MonthlyPriceTo.Value)
        .Where(p => !filter.DailyPriceFrom.HasValue || p.DailyPrice >= filter.DailyPriceFrom.Value)
        .Where(p => !filter.DailyPriceTo.HasValue || p.DailyPrice <= filter.DailyPriceTo.Value)
        .Where(p => !filter.IsMonthly || p.IsMonthly)
        .Where(p => !filter.IsDaily || p.IsDaily)
        .Where(p => !filter.HasWiFi || p.HasWiFi)
        .Where(p => !filter.IsFurnished || p.IsFurnished)
        .Where(p => !filter.HasBalcony || p.HasBalcony)
        .Where(p => !filter.MinimalNumberOfGarages.HasValue || p.NumberOfGarages >= filter.MinimalNumberOfGarages.Value)
        .Where(p => !filter.HasPool || p.HasPool)
        .Where(p => !filter.HasAirCondition || p.HasAirCondition)
        .Where(p => !filter.HasAlarm || p.HasAlarm)
        .Where(p => !filter.HasCableTV || p.HasCableTV)
        .Where(p => !filter.HasOwnHeatingSystem || p.HasOwnHeatingSystem)
        .Where(p => !filter.GardenSize.HasValue || p.GardenSize >= filter.GardenSize.Value)
        .Where(p => !filter.GarageSizeFrom.HasValue || p.GarageSize >= filter.GarageSizeFrom.Value)
        .Where(p => !filter.GarageSizeTo.HasValue || p.GarageSize <= filter.GarageSizeTo.Value)
        .Where(p => !filter.ParkingSizeFrom.HasValue || p.ParkingSize >= filter.ParkingSizeFrom.Value)
        .Where(p => !filter.ParkingSizeTo.HasValue || p.ParkingSize <= filter.ParkingSizeTo.Value));

            /* query = query.Where(p =>
                (string.IsNullOrEmpty(filter.Name) || p.Name.Contains(filter.Name)) &&
                (filter.PropertyTypeId == null || p.PropertyTypeId == filter.PropertyTypeId) &&
                (filter.CityId == null || p.CityId == filter.CityId) &&
                (filter.ApplicationUserId == null || p.ApplicationUserId == filter.ApplicationUserId) &&
                (string.IsNullOrEmpty(filter.Address) || p.Address.Contains(filter.Address)) &&
                (filter.NumberOfBathroomsFrom == null || p.NumberOfBathrooms >= filter.NumberOfRoomsFrom) &&
                (filter.NumberOfBathroomsTo == null || p.NumberOfBathrooms <= filter.NumberOfRoomsTo) &&
                (filter.SquareMetersFrom == null || p.SquareMeters >= filter.SquareMetersFrom) &&
                (filter.SquareMetersTo == null || p.SquareMeters <= filter.SquareMetersTo) &&
                (filter.MonthlyPriceFrom == null || p.MonthlyPrice >= filter.MonthlyPriceFrom) &&
                (filter.MonthlyPriceTo == null || p.MonthlyPrice <= filter.MonthlyPriceTo) &&
                (filter.DailyPriceFrom == null || p.DailyPrice >= filter.DailyPriceFrom) &&
                (filter.DailyPriceTo == null || p.DailyPrice <= filter.DailyPriceTo) &&
                (!filter.IsMonthly || p.IsMonthly) &&
                (!filter.IsDaily || p.IsDaily) &&
                (!filter.HasWiFi || p.HasWiFi) &&
                (!filter.IsFurnished || p.IsFurnished) &&
                (!filter.HasBalcony || p.HasBalcony) &&
                (filter.MinimalNumberOfGarages == null || p.NumberOfGarages >= filter.MinimalNumberOfGarages) &&
                (!filter.HasPool || p.HasPool) &&
                (!filter.HasAirCondition || p.HasAirCondition) &&
                (!filter.HasAlarm || p.HasAlarm) &&
                (!filter.HasCableTV || p.HasCableTV) &&
                (!filter.HasOwnHeatingSystem || p.HasOwnHeatingSystem) &&
                (filter.GardenSize == 0 || p.GardenSize == filter.GardenSize) &&
                (filter.GarageSizeFrom == null || p.GarageSize >= filter.GarageSizeFrom) &&
                (filter.GarageSizeTo == null || p.GarageSize <= filter.GarageSizeTo) &&
                (filter.ParkingSizeFrom == null || p.ParkingSize >= filter.ParkingSizeFrom) &&
                (filter.ParkingSizeTo == null || p.ParkingSize <= filter.ParkingSizeTo)

            ); */



            //foreach (var property in properties)
            //{
            //    _ = property.Ratings != null && property.Ratings.Any()
            //        ? property.AverageRating = property.Ratings.Average(p => p.Rating)
            //        : property.AverageRating = property.Ratings != null ? 0 : 0;
            //}
            return properties;
        }


        public async Task<List<PropertyDto>> GetByName(string name)
        {
            return await ProjectToListAsync<PropertyDto>(DatabaseContext.Properties.Where(p => p.Name.ToLower().StartsWith(name.ToLower())));
        }

        public async Task<List<PropertyDto>> GetAllAsync()
        {
            var properties = await ProjectToListAsync<PropertyDto>(DatabaseContext.Properties.Where(p => !p.IsDeleted));
     //       foreach (var property in properties)
     //       {
     //           _ = property.Ratings != null && property.Ratings.Any()
     //? property.AverageRating = property.Ratings.Average(p => p.Rating)
     //: property.AverageRating = property.Ratings != null ? 0 : 0;
     //       }
            return properties;
        }

    }
}
