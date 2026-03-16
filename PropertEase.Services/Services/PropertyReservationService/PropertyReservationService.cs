using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;

namespace PropertEase.Services.Services.PropertyReservationService
{
    public class PropertyReservationService : IPropertyReservationService
    {
        private readonly ILogger<PropertyReservationService> logger;
        private readonly UnitOfWork unitOfWork;
        private readonly IRabbitMQPublisher _publisher;

        public PropertyReservationService(IUnitOfWork unitOfWork, ILogger<PropertyReservationService> logger, IRabbitMQPublisher publisher)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
            this.logger = logger;
            _publisher = publisher;
        }

        public async Task<PropertyReservationDto> AddAsync(PropertyReservationDto entityDto)
        {
            entityDto.IsActive = true;
            entityDto.ReservationNumber = "#0000"; // placeholder; updated after insert
            Property property = await unitOfWork.PropertyRepository.GetById(entityDto.PropertyId);
            if (property.IsDaily)
                entityDto.TotalPrice = (double)(property.DailyPrice * entityDto.NumberOfDays);
            if (property.IsMonthly)
                entityDto.TotalPrice = (double)(property.MonthlyPrice * entityDto.NumberOfMonths);

            // Reject if an active reservation already overlaps the requested dates
            var db = unitOfWork.GetDatabaseContext();
            var hasOverlap = await db.PropertyReservations
                .AnyAsync(r => r.PropertyId == entityDto.PropertyId
                               && r.IsActive
                               && !r.IsDeleted
                               && r.DateOfOccupancyStart < entityDto.DateOfOccupancyEnd
                               && r.DateOfOccupancyEnd > entityDto.DateOfOccupancyStart);
            if (hasOverlap)
                throw new InvalidOperationException(
                    "Odabrani datumi nisu dostupni. Nekretnina je već rezervisana u tom periodu.");

            var inserted = await unitOfWork.PropertyReservationRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();

            var reservationNumber = $"#{inserted.Id:D4}";
            await unitOfWork.GetDatabaseContext().PropertyReservations
                .Where(r => r.Id == inserted.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ReservationNumber, reservationNumber));
            inserted.ReservationNumber = reservationNumber;
            entityDto.Id = inserted.Id;
            entityDto.ReservationNumber = reservationNumber;

            try
            {
                var client = await db.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.Id == entityDto.ClientId);
                var renter = await db.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.Id == entityDto.RenterId);

                if (client != null && renter != null)
                {
                    _publisher.Publish(new
                    {
                        ReservationId = entityDto.Id,
                        ReservationNumber = entityDto.ReservationNumber,
                        ClientEmail = client.Email ?? string.Empty,
                        ClientFullName = $"{client.Person?.FirstName} {client.Person?.LastName}".Trim(),
                        RenterEmail = renter.Email ?? string.Empty,
                        RenterFullName = $"{renter.Person?.FirstName} {renter.Person?.LastName}".Trim(),
                        PropertyName = property.Name,
                        CheckIn = entityDto.DateOfOccupancyStart,
                        CheckOut = entityDto.DateOfOccupancyEnd,
                        TotalPrice = (decimal)entityDto.TotalPrice,
                    }, "reservation.confirmed");
                }

                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == entityDto.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId = entityDto.RenterId,
                    ReservationId = entityDto.Id,
                    Message = $"Nova rezervacija za nekretninu \"{property.Name}\"",
                    ReservationNumber = entityDto.ReservationNumber,
                    PropertyName = property.Name,
                    PropertyPhotoUrl = photoUrl
                }, "reservation.notification");

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId = entityDto.ClientId,
                    ReservationId = entityDto.Id,
                    Message = $"Vaša rezervacija za nekretninu \"{property.Name}\" je uspješno kreirana",
                    ReservationNumber = entityDto.ReservationNumber,
                    PropertyName = property.Name,
                    PropertyPhotoUrl = photoUrl
                }, "reservation.notification");
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to publish messages for reservation {Id}", entityDto.Id);
            }

            return entityDto;
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyReservationRepository.GetAllAsync();
        }

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
        {
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
            // Load the tracked entity directly to avoid mapping navigation properties back to DB
            var entity = await unitOfWork.PropertyReservationRepository.GetByIdAsync(property.Id, false);
            if (entity == null)
                throw new Exception($"Reservation {property.Id} not found");

            entity.NumberOfGuests = property.NumberOfGuests;
            entity.DateOfOccupancyStart = property.DateOfOccupancyStart;
            entity.DateOfOccupancyEnd = property.DateOfOccupancyEnd;
            entity.IsActive = property.IsActive;
            entity.Description = property.Description;
            entity.NumberOfDays = property.NumberOfDays;
            entity.NumberOfMonths = property.NumberOfMonths;
            entity.TotalPrice = property.TotalPrice;
            entity.IsMonthly = property.IsMonthly;
            entity.IsDaily = property.IsDaily;

            await unitOfWork.SaveChangesAsync();
            return property;
        }

        public async Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter)
        {
            return await unitOfWork.PropertyReservationRepository.GetFiltered(filter);
        }

        public async Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search)
        {
            return await unitOfWork.PropertyReservationRepository.GetRenterBusinessReportData(search);
        }

        public async Task<int> GetUpcomingCountByPropertyAsync(int propertyId)
        {
            return await unitOfWork.PropertyReservationRepository.GetUpcomingCountByPropertyAsync(propertyId);
        }

        public async Task<int> DeactivateExpiredAsync()
        {
            return await unitOfWork.PropertyReservationRepository.DeactivateExpiredAsync();
        }

        public async Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10)
        {
            return await unitOfWork.PropertyReservationRepository.GetClientSummariesAsync(clientId, page, pageSize);
        }

        public async Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10)
        {
            return await unitOfWork.PropertyReservationRepository.GetRenterSummariesAsync(renterId, page, pageSize);
        }
    }
}
