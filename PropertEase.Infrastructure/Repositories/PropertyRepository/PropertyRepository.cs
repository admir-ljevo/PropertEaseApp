using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.PropertyRepository
{
    public class PropertyRepository : BaseRepository<Property, int>, IPropertyRepository
    {
        public PropertyRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyDto> GetByIdAsync(int id)
        {
            var today = DateTime.Today;

            var property = await DatabaseContext.Properties
                .AsNoTracking()
                .Include(p => p.City)
                .Include(p => p.PropertyType)
                .Include(p => p.ApplicationUser).ThenInclude(u => u.Person)
                .Include(p => p.Images.Where(img => !img.IsDeleted))
                .Include(p => p.PropertyReservations.Where(r => !r.IsDeleted && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Completed)))
                .Where(p => !p.IsDeleted && p.Id == id)
                .FirstOrDefaultAsync();

            var dto = Mapper.Map<PropertyDto>(property);

            if (property != null)
            {
                var activeRes = property.PropertyReservations?
                    .Where(r => r.DateOfOccupancyStart <= today && r.DateOfOccupancyEnd >= today)
                    .OrderByDescending(r => r.DateOfOccupancyEnd)
                    .FirstOrDefault();

                dto.IsAvailable = activeRes == null;
                dto.AvailableFrom = activeRes?.DateOfOccupancyEnd;
            }

            return dto;
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

        public async Task<List<PropertyRecommendationDto>> GetByIdsAsync(IReadOnlyList<int> ids)
        {
            if (ids.Count == 0) return new List<PropertyRecommendationDto>();

            var rows = await DatabaseContext.Properties
                .Where(p => ids.Contains(p.Id) && !p.IsDeleted)
                .Select(p => new PropertyRecommendationDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    CityId = p.CityId,
                    City = new PropertEase.Core.Dto.City.CityDto { Id = p.City.Id, Name = p.City.Name },
                    ApplicationUserId = p.ApplicationUserId,
                    MonthlyPrice = p.MonthlyPrice,
                    DailyPrice = p.DailyPrice,
                    IsMonthly = p.IsMonthly,
                    IsDaily = p.IsDaily,
                    IsAvailable = p.IsAvailable,
                    FirstPhotoUrl = p.Images
                        .Where(img => !img.IsDeleted)
                        .OrderBy(img => img.Id)
                        .Select(img => img.Url)
                        .FirstOrDefault(),
                })
                .AsNoTracking()
                .ToListAsync();

            var order = ids.Select((id, idx) => (id, idx)).ToDictionary(x => x.id, x => x.idx);
            rows.Sort((a, b) => order.GetValueOrDefault(a.Id, int.MaxValue)
                                     .CompareTo(order.GetValueOrDefault(b.Id, int.MaxValue)));
            return rows;
        }

        public async Task UpdateAverageRating(int propertyId, double averageRating)
        {
            await DatabaseContext.Properties
                .Where(p => p.Id == propertyId)
                .ExecuteUpdateAsync(s => s.SetProperty(p => p.AverageRating, averageRating));
        }

        public async Task<PagedResult<PropertyListDto>> GetFilteredData(PropertyFilter filter)
        {
            var today = DateTime.Today;

            var query = DatabaseContext.Properties
                .AsNoTracking()
                .Where(p => !p.IsDeleted);

            if (!string.IsNullOrEmpty(filter.Name))
                query = query.Where(p => p.Name.Contains(filter.Name));

            if (filter.PropertyTypeId.HasValue)
                query = query.Where(p => p.PropertyTypeId == filter.PropertyTypeId.Value);

            if (filter.CityId.HasValue)
                query = query.Where(p => p.CityId == filter.CityId.Value);

            if (filter.ApplicationUserId.HasValue)
                query = query.Where(p => p.ApplicationUserId == filter.ApplicationUserId.Value);

            if (!string.IsNullOrEmpty(filter.Address))
                query = query.Where(p => p.Address.Contains(filter.Address));

            if (!string.IsNullOrEmpty(filter.Description))
                query = query.Where(p => p.Description.Contains(filter.Description));

            if (filter.NumberOfRoomsFrom.HasValue)
                query = query.Where(p => p.NumberOfRooms >= filter.NumberOfRoomsFrom.Value);

            if (filter.NumberOfRoomsTo.HasValue)
                query = query.Where(p => p.NumberOfRooms <= filter.NumberOfRoomsTo.Value);

            if (filter.IsAvailable.HasValue)
            {
                if (filter.IsAvailable.Value)
                    query = query.Where(p => !p.PropertyReservations.Any(r =>
                        !r.IsDeleted && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Completed) &&
                        r.DateOfOccupancyStart <= today && r.DateOfOccupancyEnd >= today));
                else
                    query = query.Where(p => p.PropertyReservations.Any(r =>
                        !r.IsDeleted && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Completed) &&
                        r.DateOfOccupancyStart <= today && r.DateOfOccupancyEnd >= today));
            }

            if (filter.PriceFrom.HasValue)
                query = query.Where(p =>
                    (p.IsMonthly && p.MonthlyPrice >= filter.PriceFrom.Value) ||
                    (p.IsDaily && p.DailyPrice >= filter.PriceFrom.Value));

            if (filter.PriceTo.HasValue)
                query = query.Where(p =>
                    (p.IsMonthly && p.MonthlyPrice <= filter.PriceTo.Value) ||
                    (p.IsDaily && p.DailyPrice <= filter.PriceTo.Value));

            var page = filter.Page <= 0 ? 1 : filter.Page;
            var pageSize = Math.Min(filter.PageSize <= 0 ? 10 : filter.PageSize, 100);

            var totalCount = await query.CountAsync();

            // use select instead of include for perfromance
            var items = await query
                .OrderBy(p => p.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(p => new PropertyListDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Address = p.Address,
                    CityId = p.CityId,
                    City = p.City == null ? null : new PropertEase.Core.Dto.City.CityDto
                    {
                        Id = p.City.Id,
                        Name = p.City.Name
                    },
                    PropertyTypeId = p.PropertyTypeId,
                    PropertyType = p.PropertyType == null ? null : new PropertEase.Core.Dto.PropertyType.PropertyTypeDto
                    {
                        Id = p.PropertyType.Id,
                        Name = p.PropertyType.Name
                    },
                    ApplicationUserId = p.ApplicationUserId,
                    NumberOfRooms = p.NumberOfRooms,
                    NumberOfBathrooms = p.NumberOfBathrooms,
                    SquareMeters = p.SquareMeters,
                    MonthlyPrice = p.MonthlyPrice,
                    DailyPrice = p.DailyPrice,
                    IsMonthly = p.IsMonthly,
                    IsDaily = p.IsDaily,
                    IsAvailable = !p.PropertyReservations.Any(r =>
                        !r.IsDeleted && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Completed) &&
                        r.DateOfOccupancyStart <= today && r.DateOfOccupancyEnd >= today),
                    AvailableFrom = p.PropertyReservations
                        .Where(r => !r.IsDeleted && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Completed) &&
                            r.DateOfOccupancyStart <= today && r.DateOfOccupancyEnd >= today)
                        .OrderByDescending(r => r.DateOfOccupancyEnd)
                        .Select(r => (DateTime?)r.DateOfOccupancyEnd)
                        .FirstOrDefault(),
                    Description = p.Description,

                    AverageRating = p.Ratings.Any(r => !r.IsDeleted)
                        ? p.Ratings.Where(r => !r.IsDeleted).Average(r => r.Rating)
                        : 0,
                    FirstPhotoUrl = p.Images
                        .Where(img => !img.IsDeleted)
                        .OrderBy(img => img.Id)
                        .Select(img => img.Url)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return new PagedResult<PropertyListDto>
            {
                Items = items,
                TotalCount = totalCount
            };
        }
    }
}
