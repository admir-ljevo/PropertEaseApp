using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;

namespace PropertEase.Infrastructure.Repositories.PropertyReservationRepository
{
    public class PropertyReservationRepository : BaseRepository<PropertyReservation, int>, IPropertyReservationRepository
    {
        public PropertyReservationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
        {
            var pr = await DatabaseContext.PropertyReservations
                .AsNoTracking()
                .Where(r => r.Id == id && !r.IsDeleted)
                .Include(r => r.Client).ThenInclude(c => c.Person)
                .Include(r => r.Renter).ThenInclude(r => r.Person)
                .Include(r => r.Property).ThenInclude(p => p.City)
                .Include(r => r.Property).ThenInclude(p => p.PropertyType)
                .Include(r => r.Property).ThenInclude(p => p.Images)
                .FirstOrDefaultAsync();

            if (pr == null) return null!;

            var isPaid = pr.Status == Core.Enumerations.ReservationStatus.Completed
                || await DatabaseContext.Payments
                    .AnyAsync(p => p.ReservationId == id && p.Status == Core.Enumerations.PaymentStatus.Completed && !p.IsDeleted);;

            string? cancelledByName = null;
            if (pr.CancelledById.HasValue)
            {
                cancelledByName = await DatabaseContext.Persons
                    .AsNoTracking()
                    .Where(p => p.ApplicationUserId == pr.CancelledById.Value)
                    .Select(p => p.FirstName + " " + p.LastName)
                    .FirstOrDefaultAsync();
            }

            string? confirmedByName = null;
            if (pr.ConfirmedById.HasValue)
            {
                confirmedByName = await DatabaseContext.Persons
                    .AsNoTracking()
                    .Where(p => p.ApplicationUserId == pr.ConfirmedById.Value)
                    .Select(p => p.FirstName + " " + p.LastName)
                    .FirstOrDefaultAsync();
            }

            return new PropertyReservationDto
            {
                Id = pr.Id,
                IsPaid = isPaid,
                ReservationNumber = pr.ReservationNumber,
                Description = pr.Description,
                PropertyId = pr.PropertyId,
                ClientId = pr.ClientId,
                RenterId = pr.RenterId,
                NumberOfGuests = pr.NumberOfGuests,
                DateOfOccupancyStart = pr.DateOfOccupancyStart,
                DateOfOccupancyEnd = pr.DateOfOccupancyEnd,
                NumberOfDays = pr.NumberOfDays,
                NumberOfMonths = pr.NumberOfMonths,
                TotalPrice = pr.TotalPrice,
                IsMonthly = pr.IsMonthly,
                IsDaily = pr.IsDaily,
                Status = pr.Status,
                CancellationReason = pr.CancellationReason,
                CancelledById = pr.CancelledById,
                CancelledAt = pr.CancelledAt,
                CancelledByName = cancelledByName,
                ConfirmedById = pr.ConfirmedById,
                ConfirmedAt = pr.ConfirmedAt,
                ConfirmedByName = confirmedByName,
                Client = new ApplicationUserDto
                {
                    Person = new PersonDto
                    {
                        FirstName = pr.Client?.Person?.FirstName,
                        LastName = pr.Client?.Person?.LastName,
                    }
                },
                Renter = new ApplicationUserDto
                {
                    Person = new PersonDto
                    {
                        FirstName = pr.Renter?.Person?.FirstName,
                        LastName = pr.Renter?.Person?.LastName,
                    }
                },
                Property = new PropertyDto
                {
                    Id = pr.PropertyId,
                    Name = pr.Property.Name,
                    Address = pr.Property.Address,
                    Description = pr.Property.Description,
                    NumberOfRooms = pr.Property.NumberOfRooms,
                    NumberOfBathrooms = pr.Property.NumberOfBathrooms,
                    SquareMeters = pr.Property.SquareMeters,
                    Capacity = pr.Property.Capacity,
                    MonthlyPrice = pr.Property.MonthlyPrice,
                    DailyPrice = pr.Property.DailyPrice,
                    IsMonthly = pr.Property.IsMonthly,
                    IsDaily = pr.Property.IsDaily,
                    HasWiFi = pr.Property.HasWiFi,
                    IsFurnished = pr.Property.IsFurnished,
                    HasBalcony = pr.Property.HasBalcony,
                    HasPool = pr.Property.HasPool,
                    HasAirCondition = pr.Property.HasAirCondition,
                    HasParking = pr.Property.HasParking,
                    HasGarage = pr.Property.HasGarage,
                    AverageRating = pr.Property.AverageRating,
                    City = pr.Property.City == null ? null! : new Core.Dto.City.CityDto
                    {
                        Id = pr.Property.City.Id,
                        Name = pr.Property.City.Name,
                    },
                    PropertyTypeId = pr.Property.PropertyTypeId,
                    PropertyType = pr.Property.PropertyType == null ? null! : new Core.Dto.PropertyType.PropertyTypeDto
                    {
                        Id = pr.Property.PropertyType.Id,
                        Name = pr.Property.PropertyType.Name,
                    },
                    Photos = pr.Property.Images
                        .Select(p => new Core.Dto.Photo.PhotoDto { Id = p.Id, Url = p.Url })
                        .ToList(),
                },
            };
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<PropertyReservationDto>(
                DatabaseContext.PropertyReservations
                    .AsNoTracking());
        }

        public async Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter)
        {
            var reservationsQuery = DatabaseContext.PropertyReservations
                .Where(pr =>
                    (!filter.DateOccupancyStartedStart.HasValue || pr.DateOfOccupancyStart >= filter.DateOccupancyStartedStart.Value) &&
                    (!filter.DateOccupancyStartedEnd.HasValue || pr.DateOfOccupancyStart <= filter.DateOccupancyStartedEnd.Value) &&
                    (!filter.DateOccupancyEnded.HasValue || pr.DateOfOccupancyEnd <= filter.DateOccupancyEnded.Value) &&
                    (!filter.totalPriceFrom.HasValue || pr.TotalPrice >= filter.totalPriceFrom.Value) &&
                    (!filter.totalPriceTo.HasValue || pr.TotalPrice <= filter.totalPriceTo.Value) &&
                    (!filter.clientId.HasValue || pr.ClientId == filter.clientId) &&
                    (!filter.propertyId.HasValue || pr.PropertyId == filter.propertyId) &&
                    (!filter.renterId.HasValue || pr.RenterId == filter.renterId) &&
                    (!filter.status.HasValue || (int)pr.Status == filter.status.Value) &&
                    (!filter.isActive.HasValue || (filter.isActive.Value
                        ? (pr.Status == Core.Enumerations.ReservationStatus.Confirmed || pr.Status == Core.Enumerations.ReservationStatus.Paid)
                        : (pr.Status != Core.Enumerations.ReservationStatus.Confirmed && pr.Status != Core.Enumerations.ReservationStatus.Paid))) &&
                    (filter.propertyTypeId == null || filter.propertyTypeId == pr.Property.PropertyTypeId) &&
                    !pr.IsDeleted);

            if (!string.IsNullOrEmpty(filter.propertyName))
            {
                reservationsQuery = reservationsQuery.Where(pr => pr.Property.Name.Contains(filter.propertyName));
            }

            var totalCount = await reservationsQuery.CountAsync();

            var reservationsDto = await reservationsQuery
                .OrderBy(pr => pr.DateOfOccupancyStart)
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(pr => new PropertyReservationDto
                {
                    Id = pr.Id,
                    ReservationNumber = pr.ReservationNumber,
                    Description = pr.Description,
                    PropertyId = pr.PropertyId,
                    ClientId = pr.ClientId,
                    RenterId = pr.RenterId,
                    NumberOfGuests = pr.NumberOfGuests,
                    DateOfOccupancyStart = pr.DateOfOccupancyStart,
                    DateOfOccupancyEnd = pr.DateOfOccupancyEnd,
                    NumberOfDays = pr.NumberOfDays,
                    NumberOfMonths = pr.NumberOfMonths,
                    TotalPrice = pr.TotalPrice,
                    IsMonthly = pr.IsMonthly,
                    IsDaily = pr.IsDaily,
                    Status = pr.Status,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = pr.Client.Person.FirstName,
                            LastName = pr.Client.Person.LastName,
                        }
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = pr.Renter.Person.FirstName,
                            LastName = pr.Renter.Person.LastName,
                        }
                    },
                    Property = new PropertyDto
                    {
                        Id = pr.PropertyId,
                        Name = pr.Property.Name,
                        Address = pr.Property.Address,
                        City = pr.Property.City == null ? null! : new Core.Dto.City.CityDto
                        {
                            Id = pr.Property.City.Id,
                            Name = pr.Property.City.Name,
                        },
                        PropertyTypeId = pr.Property.PropertyTypeId,
                        PropertyType = pr.Property.PropertyType == null ? null! : new Core.Dto.PropertyType.PropertyTypeDto
                        {
                            Id = pr.Property.PropertyType.Id,
                            Name = pr.Property.PropertyType.Name,
                        },
                        Photos = pr.Property.Images
                            .Where(img => !img.IsDeleted)
                            .OrderBy(img => img.Id)
                            .Take(1)
                            .Select(img => new Core.Dto.Photo.PhotoDto { Id = img.Id, Url = img.Url })
                            .ToList(),
                    },
                })
                .ToListAsync();

            return new PropertEase.Core.Dto.PagedResult<PropertyReservationDto> { Items = reservationsDto, TotalCount = totalCount };
        }

        public async Task<(int TotalClientCount, int PropertyClientCount, Dictionary<int, int> CoOccurrences)>
            GetRecommendationDataAsync(int propertyId)
        {
            var totalClientCount = await DatabaseContext.PropertyReservations
                .Where(r => !r.IsDeleted)
                .Select(r => r.ClientId)
                .Distinct()
                .CountAsync();

            var propertyClientIds = await DatabaseContext.PropertyReservations
                .Where(r => r.PropertyId == propertyId && !r.IsDeleted)
                .Select(r => r.ClientId)
                .Distinct()
                .ToListAsync();

            if (propertyClientIds.Count == 0)
                return (totalClientCount, 0, new Dictionary<int, int>());

          
            var coOccurrencePairs = await DatabaseContext.PropertyReservations
                .Where(r => propertyClientIds.Contains(r.ClientId)
                            && r.PropertyId != propertyId
                            && !r.IsDeleted)
                .Select(r => new { r.PropertyId, r.ClientId })
                .Distinct()
                .ToListAsync();

            var coOccurrences = coOccurrencePairs
                .GroupBy(p => p.PropertyId)
                .ToDictionary(g => g.Key, g => g.Count());

            return (totalClientCount, propertyClientIds.Count, coOccurrences);
        }

        public async Task<List<PropertyReservationDto>> GetForReportAsync(int? ownerId, DateTime? from, DateTime? to)
        {
            var query = DatabaseContext.PropertyReservations
                .AsNoTracking()
                .Where(pr => !pr.IsDeleted);

            if (ownerId.HasValue)
                query = query.Where(pr => pr.Property.ApplicationUserId == ownerId.Value);
            if (from.HasValue)
                query = query.Where(pr => pr.DateOfOccupancyStart >= from.Value);
            if (to.HasValue)
                query = query.Where(pr => pr.DateOfOccupancyEnd <= to.Value);

            return await query
                .OrderBy(pr => pr.DateOfOccupancyStart)
                .Select(pr => new PropertyReservationDto
                {
                    Id = pr.Id,
                    ReservationNumber = pr.ReservationNumber,
                    DateOfOccupancyStart = pr.DateOfOccupancyStart,
                    DateOfOccupancyEnd = pr.DateOfOccupancyEnd,
                    TotalPrice = pr.TotalPrice,
                    IsRefunded = DatabaseContext.Payments
                        .Any(p => p.ReservationId == pr.Id && !p.IsDeleted && p.Status == PaymentStatus.Refunded),
                    Client = new ApplicationUserDto { UserName = pr.Client.UserName },
                    Property = new PropertyDto
                    {
                        Id = pr.PropertyId,
                        Name = pr.Property.Name,
                        ApplicationUserId = pr.Property.ApplicationUserId,
                    },
                })
                .ToListAsync();
        }

        public Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10)
            => GetSummariesAsync(pr => pr.ClientId == clientId && !pr.IsDeleted, page, pageSize);

        public Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10)
            => GetSummariesAsync(pr => pr.RenterId == renterId && !pr.IsDeleted, page, pageSize);

        private async Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetSummariesAsync(
            System.Linq.Expressions.Expression<Func<PropertyReservation, bool>> predicate,
            int page,
            int pageSize)
        {
            var query = DatabaseContext.PropertyReservations.AsNoTracking().Where(predicate);
            var totalCount = await query.CountAsync();
            var items = await query
                .OrderByDescending(pr => pr.DateOfOccupancyStart)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(pr => new ReservationSummaryDto
                {
                    Id = pr.Id,
                    ReservationNumber = pr.ReservationNumber,
                    DateOfOccupancyStart = pr.DateOfOccupancyStart,
                    DateOfOccupancyEnd = pr.DateOfOccupancyEnd,
                    TotalPrice = pr.TotalPrice,
                    Status = pr.Status,
                    PropertyName = pr.Property.Name,
                    CancellationReason = pr.CancellationReason,
                })
                .ToListAsync();
            return new PropertEase.Core.Dto.PagedResult<ReservationSummaryDto> { Items = items, TotalCount = totalCount };
        }

        public async Task<int> GetUpcomingCountByPropertyAsync(int propertyId)
        {
            return await DatabaseContext.PropertyReservations
                .CountAsync(r => r.PropertyId == propertyId
                                 && !r.IsDeleted
                                 && r.DateOfOccupancyEnd >= DateTime.UtcNow);
        }

        public async Task<int> DeactivateExpiredAsync()
        {
            return await DatabaseContext.PropertyReservations
                .Where(r => (r.Status == PropertEase.Core.Enumerations.ReservationStatus.Confirmed
                          || r.Status == PropertEase.Core.Enumerations.ReservationStatus.Paid)
                         && r.DateOfOccupancyEnd <= DateTime.Now
                         && !r.IsDeleted)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.Status, PropertEase.Core.Enumerations.ReservationStatus.Completed));
        }

        public async new Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search)
        {
            return await DatabaseContext.PropertyReservations
                .AsNoTracking()
                .Where(x => !x.IsDeleted && search.DateFrom <= x.CreatedAt && search.DateTo >= x.CreatedAt && search.RenterId == x.RenterId)
                .Select(x => new PropertyReservationDto
                {
                    Id = x.Id,
                    ReservationNumber = x.ReservationNumber,
                    DateOfOccupancyStart = x.DateOfOccupancyStart,
                    DateOfOccupancyEnd = x.DateOfOccupancyEnd,
                    TotalPrice = x.TotalPrice,
                    NumberOfDays = x.NumberOfDays,
                    NumberOfMonths = x.NumberOfMonths,
                    IsMonthly = x.IsMonthly,
                    IsDaily = x.IsDaily,
                    Client = new ApplicationUserDto { UserName = x.Client.UserName },
                    Property = new PropertyDto { Id = x.PropertyId, Name = x.Property.Name },
                })
                .ToListAsync();
        }
    }
}
