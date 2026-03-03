using AutoMapper;
using Microsoft.EntityFrameworkCore;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Entities;
using MobiFon.Core.Filters;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.PropertyRepository
{
    public class PropertyRepository : BaseRepository<Property, int>, IPropertyRepository
    {
        public PropertyRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<PropertyDto>(
                DatabaseContext.Properties
                    .AsNoTracking()
                    .Where(p => !p.IsDeleted && p.Id == id));
        }

        public async Task<List<PropertyDto>> GetAllAsync()
        {
            return await ProjectToListAsync<PropertyDto>(
                DatabaseContext.Properties
                    .AsNoTracking()
                    .Where(p => !p.IsDeleted));
        }

        public async Task<List<PropertyDto>> GetByName(string name)
        {
            return await ProjectToListAsync<PropertyDto>(
                DatabaseContext.Properties
                    .AsNoTracking()
                    .Where(p => !p.IsDeleted && p.Name.ToLower().StartsWith(name.ToLower())));
        }

        public async Task<List<PropertyDto>> GetFilteredData(PropertyFilter filter)
        {
            var query = DatabaseContext.Properties
                .AsNoTracking()
                .Where(p =>
                    !p.IsDeleted &&
                    (string.IsNullOrEmpty(filter.Name) || p.Name.Contains(filter.Name)) &&
                    (!filter.PropertyTypeId.HasValue || p.PropertyTypeId == filter.PropertyTypeId.Value) &&
                    (!filter.CityId.HasValue || p.CityId == filter.CityId.Value) &&
                    (!filter.ApplicationUserId.HasValue || p.ApplicationUserId == filter.ApplicationUserId.Value) &&
                    (string.IsNullOrEmpty(filter.Address) || p.Address.Contains(filter.Address)) &&
                    (string.IsNullOrEmpty(filter.Description) || p.Description.Contains(filter.Description)) &&
                    (!filter.NumberOfRoomsFrom.HasValue || p.NumberOfRooms >= filter.NumberOfRoomsFrom.Value) &&
                    (!filter.NumberOfRoomsTo.HasValue || p.NumberOfRooms <= filter.NumberOfRoomsTo.Value) &&
                    (!filter.NumberOfBathroomsFrom.HasValue || p.NumberOfBathrooms >= filter.NumberOfBathroomsFrom.Value) &&
                    (!filter.NumberOfBathroomsTo.HasValue || p.NumberOfBathrooms <= filter.NumberOfBathroomsTo.Value) &&
                    (!filter.SquareMetersFrom.HasValue || p.SquareMeters >= filter.SquareMetersFrom.Value) &&
                    (!filter.SquareMetersTo.HasValue || p.SquareMeters <= filter.SquareMetersTo.Value) &&
                    (!filter.CapacityFrom.HasValue || p.Capacity >= filter.CapacityFrom.Value) &&
                    (!filter.CapacityTo.HasValue || p.Capacity <= filter.CapacityTo.Value) &&
                    (!filter.PriceFrom.HasValue || p.MonthlyPrice >= filter.PriceFrom.Value || p.DailyPrice >= filter.PriceFrom.Value) &&
                    (!filter.PriceTo.HasValue || p.MonthlyPrice <= filter.PriceTo.Value || p.DailyPrice <= filter.PriceTo.Value) &&
                    (!filter.IsMonthly || p.IsMonthly) &&
                    (!filter.IsDaily || p.IsDaily) &&
                    (!filter.HasWiFi || p.HasWiFi) &&
                    (!filter.IsFurnished || p.IsFurnished) &&
                    (!filter.HasBalcony || p.HasBalcony) &&
                    (!filter.IsAvailable.HasValue || p.IsAvailable == filter.IsAvailable.Value) &&
                    (!filter.MinimalNumberOfGarages.HasValue || p.NumberOfGarages >= filter.MinimalNumberOfGarages.Value) &&
                    (!filter.HasPool || p.HasPool) &&
                    (!filter.HasAirCondition || p.HasAirCondition) &&
                    (!filter.HasAlarm || p.HasAlarm) &&
                    (!filter.HasCableTV || p.HasCableTV) &&
                    (!filter.HasOwnHeatingSystem || p.HasOwnHeatingSystem) &&
                    (!filter.GardenSize.HasValue || p.GardenSize >= filter.GardenSize.Value) &&
                    (!filter.GarageSizeFrom.HasValue || p.GarageSize >= filter.GarageSizeFrom.Value) &&
                    (!filter.GarageSizeTo.HasValue || p.GarageSize <= filter.GarageSizeTo.Value) &&
                    (!filter.ParkingSizeFrom.HasValue || p.ParkingSize >= filter.ParkingSizeFrom.Value) &&
                    (!filter.ParkingSizeTo.HasValue || p.ParkingSize <= filter.ParkingSizeTo.Value)
                );

            return await ProjectToListAsync<PropertyDto>(query);
        }
    }
}
