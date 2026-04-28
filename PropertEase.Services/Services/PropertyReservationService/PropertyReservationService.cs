using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Exceptions;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Core.StateMachines;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Infrastructure.UnitOfWork;

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
            var targetStatus = ReservationStatus.Pending;
            entityDto.Status = targetStatus;
            entityDto.ReservationNumber = "#0000";

            Property property = await unitOfWork.PropertyRepository.GetById(entityDto.PropertyId);

            // server side price calculation
            var totalHours = (entityDto.DateOfOccupancyEnd - entityDto.DateOfOccupancyStart).TotalHours;
            var totalDays   = (int)Math.Ceiling(totalHours / 24.0);
            var totalMonths = (int)Math.Ceiling(totalDays  / 30.0);

            entityDto.NumberOfDays   = Math.Max(totalDays, 1);
            entityDto.NumberOfMonths = Math.Max(totalMonths, 1);

            if (property.IsDaily)
                entityDto.TotalPrice = (double)(property.DailyPrice   * entityDto.NumberOfDays);
            if (property.IsMonthly)
                entityDto.TotalPrice = (double)(property.MonthlyPrice  * entityDto.NumberOfMonths);

            // overlap check
            var db = unitOfWork.GetDatabaseContext();
            var hasOverlap = await db.PropertyReservations
                .AnyAsync(r => r.PropertyId == entityDto.PropertyId
                               && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid)
                               && !r.IsDeleted
                               && r.DateOfOccupancyStart < entityDto.DateOfOccupancyEnd
                               && r.DateOfOccupancyEnd   > entityDto.DateOfOccupancyStart);
            if (hasOverlap)
                throw new BusinessException(
                    "Odabrani datumi nisu dostupni. Nekretnina je već rezervisana u tom periodu.");

            var inserted = await unitOfWork.PropertyReservationRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();

            var reservationNumber = $"#{inserted.Id:D4}";
            await db.PropertyReservations
                .Where(r => r.Id == inserted.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ReservationNumber, reservationNumber));

            entityDto.Id                = inserted.Id;
            entityDto.ReservationNumber = reservationNumber;

            // send notifications
            try
            {
                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == entityDto.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = entityDto.RenterId,
                    ReservationId     = entityDto.Id,
                    Title             = "Novi zahtjev za rezervaciju",
                    Message           = $"Novi zahtjev za nekretninu \"{property.Name}\" čeka vašu potvrdu",
                    ReservationNumber = entityDto.ReservationNumber,
                    PropertyName      = property.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId            = entityDto.ClientId,
                    ReservationId     = entityDto.Id,
                    Title             = "Zahtjev poslan",
                    Message           = $"Vaš zahtjev za nekretninu \"{property.Name}\" je poslan iznajmljivaču na potvrdu",
                    ReservationNumber = entityDto.ReservationNumber,
                    PropertyName      = property.Name,
                    PropertyPhotoUrl  = photoUrl
                }, "reservation.notification");
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to publish messages for reservation {Id}", entityDto.Id);
            }

            return entityDto;
        }

        public async Task<PropertyReservationDto> ConfirmReservationAsync(int id, int actorId)
        {
            var db = unitOfWork.GetDatabaseContext();

            var entity = await db.PropertyReservations.FindAsync(id)
                ?? throw new NotFoundException("Reservation", id);

            if (entity.Status != ReservationStatus.Pending)
                throw new BusinessException("Samo rezervacije na čekanju mogu biti potvrđene.");

            // overlap check at confirm time 
            var hasOverlap = await db.PropertyReservations
                .AnyAsync(r => r.Id != id
                               && r.PropertyId == entity.PropertyId
                               && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid)
                               && !r.IsDeleted
                               && r.DateOfOccupancyStart < entity.DateOfOccupancyEnd
                               && r.DateOfOccupancyEnd   > entity.DateOfOccupancyStart);
            if (hasOverlap)
                throw new BusinessException(
                    "Nekretnina je u međuvremenu postala nedostupna za odabrane datume.");

            ReservationStateMachine.Transition(entity, ReservationStatus.Confirmed, actorId);

            var now = DateTime.UtcNow;
            entity.ConfirmedAt   = now;
            entity.ConfirmedById = actorId;

            db.PropertyReservations.Update(entity);
            await unitOfWork.SaveChangesAsync();

            await SyncPropertyAvailabilityAsync(entity.PropertyId);

            // send notifications
            try
            {
                var prop = await db.Properties
                    .AsNoTracking()
                    .Where(p => p.Id == entity.PropertyId && !p.IsDeleted)
                    .Select(p => new { p.Name })
                    .FirstOrDefaultAsync();

                var photoUrl = await db.Photos
                    .Where(p => p.PropertyId == entity.PropertyId && !p.IsDeleted)
                    .Select(p => p.Url)
                    .FirstOrDefaultAsync();

                var userIds = new[] { entity.ClientId, entity.RenterId, actorId }.Distinct().ToArray();
                var userInfos = await db.Users
                    .AsNoTracking()
                    .Where(u => userIds.Contains(u.Id))
                    .Select(u => new {
                        u.Id,
                        u.Email,
                        FullName = db.Persons
                            .Where(p => p.ApplicationUserId == u.Id)
                            .Select(p => p.FirstName + " " + p.LastName)
                            .FirstOrDefault() ?? u.UserName
                    })
                    .ToDictionaryAsync(u => u.Id);

                userInfos.TryGetValue(actorId,        out var actor);
                userInfos.TryGetValue(entity.ClientId, out var client);
                userInfos.TryGetValue(entity.RenterId, out var renter);

                _publisher.Publish(new ReservationConfirmedMessage
                {
                    ReservationId    = entity.Id,
                    ReservationNumber = entity.ReservationNumber,
                    PropertyName     = prop?.Name ?? string.Empty,
                    PropertyPhotoUrl = photoUrl,
                    CheckIn          = entity.DateOfOccupancyStart,
                    CheckOut         = entity.DateOfOccupancyEnd,
                    TotalPrice       = (decimal)entity.TotalPrice,
                    ActorFullName    = actor?.FullName ?? string.Empty,
                    ClientUserId     = entity.ClientId,
                    ClientEmail      = client?.Email ?? string.Empty,
                    ClientFullName   = client?.FullName ?? string.Empty,
                    RenterEmail      = renter?.Email ?? string.Empty,
                    RenterFullName   = renter?.FullName ?? string.Empty
                }, "reservation.confirmed");
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to publish confirm notification for reservation {Id}", id);
            }

            return await unitOfWork.PropertyReservationRepository.GetByIdAsync(id);
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
            => await unitOfWork.PropertyReservationRepository.GetAllAsync();

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
            => await unitOfWork.PropertyReservationRepository.GetByIdAsync(id);

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var db = unitOfWork.GetDatabaseContext();

            var reservation = await db.PropertyReservations.FindAsync(id);
            if (reservation == null) return;

            if (reservation.Status == ReservationStatus.Pending
                || reservation.Status == ReservationStatus.Confirmed
                || reservation.Status == ReservationStatus.Paid)
                throw new InvalidOperationException("Cannot delete a reservation that is pending, confirmed or paid. Cancel it first.");

            foreach (var n in db.ReservationNotifications.Where(n => n.ReservationId == id && !n.IsDeleted).ToList())
                n.IsDeleted = true;

            reservation.IsDeleted = true;
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(PropertyReservationDto entity)
        {
            unitOfWork.PropertyReservationRepository.Update(entity);
            unitOfWork.SaveChanges();
        }

        public async Task<PropertyReservationDto> UpdateAsync(PropertyReservationDto property)
        {
            var entity = await unitOfWork.PropertyReservationRepository.GetByIdAsync(property.Id, false)
                ?? throw new NotFoundException("Reservation", property.Id);

            entity.NumberOfGuests       = property.NumberOfGuests;
            entity.DateOfOccupancyStart = property.DateOfOccupancyStart;
            entity.DateOfOccupancyEnd   = property.DateOfOccupancyEnd;
            entity.Description          = property.Description;
            entity.NumberOfDays         = property.NumberOfDays;
            entity.NumberOfMonths       = property.NumberOfMonths;
            entity.TotalPrice           = property.TotalPrice;
            entity.IsMonthly            = property.IsMonthly;
            entity.IsDaily              = property.IsDaily;

            if (entity.Status != property.Status)
                ReservationStateMachine.Transition(entity, property.Status,
                    reason: property.CancellationReason);

            await unitOfWork.SaveChangesAsync();
            return property;
        }

        public async Task<PropertyReservationDto> UpdateWithNotificationAsync(
            int id,
            PropertyReservationUpsertDto dto,
            int? actorId = null)
        {
            var entity = await unitOfWork.PropertyReservationRepository.GetByIdAsync(id, false)
                ?? throw new NotFoundException("Reservation", id);

            var db = unitOfWork.GetDatabaseContext();
            var originalStatus = entity.Status;

            // cancelling a paid reservation must go through the refund endpoint
            if (dto.Status == ReservationStatus.Cancelled && entity.Status != ReservationStatus.Cancelled)
            {
                var hasPaidPayment = await db.Payments
                    .AnyAsync(p => p.ReservationId == id
                                   && p.Status == PaymentStatus.Completed
                                   && !p.IsDeleted);
                if (hasPaidPayment)
                    throw new BusinessException(
                        "Rezervacija ima izvršenu uplatu. Za otkazanje koristite endpoint za povrat sredstava (refund).");
            }

            // overlap check when dates are being changed
            if (entity.DateOfOccupancyStart != dto.DateOfOccupancyStart ||
                entity.DateOfOccupancyEnd   != dto.DateOfOccupancyEnd)
            {
                var hasOverlap = await db.PropertyReservations
                    .AnyAsync(r => r.Id != id
                                   && r.PropertyId == entity.PropertyId
                                   && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid)
                                   && !r.IsDeleted
                                   && r.DateOfOccupancyStart < dto.DateOfOccupancyEnd
                                   && r.DateOfOccupancyEnd   > dto.DateOfOccupancyStart);
                if (hasOverlap)
                    throw new BusinessException(
                        "Odabrani datumi nisu dostupni. Nekretnina je već rezervisana u tom periodu.");
            }

            entity.NumberOfGuests       = dto.NumberOfGuests;
            entity.DateOfOccupancyStart = dto.DateOfOccupancyStart;
            entity.DateOfOccupancyEnd   = dto.DateOfOccupancyEnd;
            entity.Description          = dto.Description;
            entity.IsMonthly            = dto.IsMonthly;
            entity.IsDaily              = dto.IsDaily;

            // server side calculation
            var totalHours = (entity.DateOfOccupancyEnd - entity.DateOfOccupancyStart).TotalHours;
            var days   = (int)Math.Ceiling(totalHours / 24.0);
            var months = (int)Math.Ceiling(days / 30.0);
            entity.NumberOfDays   = Math.Max(days, 1);
            entity.NumberOfMonths = Math.Max(months, 1);

            // state machine
            if (entity.Status != dto.Status)
                ReservationStateMachine.Transition(entity, dto.Status, actorId, dto.CancellationReason);

            await unitOfWork.SaveChangesAsync();

            await SyncPropertyAvailabilityAsync(entity.PropertyId);

            // send notification only when status actually changed
            if (originalStatus != entity.Status)
            {
                try
                {
                    var prop = await db.Properties
                        .AsNoTracking()
                        .Where(p => p.Id == entity.PropertyId && !p.IsDeleted)
                        .Select(p => new
                        {
                            p.Name,
                            PhotoUrl = p.Images.Where(i => !i.IsDeleted).Select(i => i.Url).FirstOrDefault()
                        })
                        .FirstOrDefaultAsync();

                    if (entity.Status == ReservationStatus.Cancelled)
                    {
                        var userIds = new[] { entity.ClientId, entity.RenterId }
                            .Concat(actorId.HasValue ? new[] { actorId.Value } : Array.Empty<int>())
                            .Distinct().ToArray();

                        var userInfos = await db.Users
                            .AsNoTracking()
                            .Where(u => userIds.Contains(u.Id))
                            .Select(u => new {
                                u.Id,
                                u.Email,
                                FullName = db.Persons
                                    .Where(p => p.ApplicationUserId == u.Id)
                                    .Select(p => p.FirstName + " " + p.LastName)
                                    .FirstOrDefault() ?? u.UserName
                            })
                            .ToDictionaryAsync(u => u.Id);

                        userInfos.TryGetValue(entity.ClientId, out var client);
                        userInfos.TryGetValue(entity.RenterId, out var renter);
                        var actorName = actorId.HasValue && userInfos.TryGetValue(actorId.Value, out var actor)
                            ? actor.FullName ?? string.Empty
                            : string.Empty;

                        _publisher.Publish(new ReservationCancelledMessage
                        {
                            ReservationId      = id,
                            ReservationNumber  = entity.ReservationNumber,
                            PropertyName       = prop?.Name ?? string.Empty,
                            CancellationReason = entity.CancellationReason ?? string.Empty,
                            CheckIn            = entity.DateOfOccupancyStart,
                            CheckOut           = entity.DateOfOccupancyEnd,
                            TotalPrice         = (decimal)entity.TotalPrice,
                            PropertyPhotoUrl   = prop?.PhotoUrl,
                            ActorFullName      = actorName,
                            ClientUserId       = entity.ClientId,
                            ClientEmail        = client?.Email ?? string.Empty,
                            ClientFullName     = client?.FullName ?? string.Empty,
                            RenterUserId       = entity.RenterId > 0 ? entity.RenterId : null,
                            RenterEmail        = renter?.Email ?? string.Empty,
                            RenterFullName     = renter?.FullName ?? string.Empty
                        }, "reservation.cancelled");
                    }
                    else
                    {
                        _publisher.Publish(new ReservationNotificationMessage
                        {
                            UserId            = entity.ClientId,
                            ReservationId     = id,
                            Title             = "Rezervacija ažurirana",
                            Message           = "Vaša rezervacija je ažurirana",
                            ReservationNumber = entity.ReservationNumber,
                            PropertyName      = prop?.Name,
                            PropertyPhotoUrl  = prop?.PhotoUrl
                        }, "reservation.notification");
                    }
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Failed to publish update notification for reservation {Id}", id);
                }
            }

            return await unitOfWork.PropertyReservationRepository.GetByIdAsync(id);
        }

        public async Task SyncPropertyAvailabilityAsync(int propertyId)
        {
            var db = unitOfWork.GetDatabaseContext();
            var hasConfirmedReservation = await db.PropertyReservations
                .AnyAsync(r => r.PropertyId == propertyId
                               && (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid)
                               && !r.IsDeleted);

            var property = await db.Properties.FindAsync(propertyId);
            if (property == null) return;

            property.IsAvailable = !hasConfirmedReservation;
            await unitOfWork.SaveChangesAsync();
        }

        public async Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter)
            => await unitOfWork.PropertyReservationRepository.GetFiltered(filter);

        public async Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search)
            => await unitOfWork.PropertyReservationRepository.GetRenterBusinessReportData(search);

        public async Task<int> GetUpcomingCountByPropertyAsync(int propertyId)
            => await unitOfWork.PropertyReservationRepository.GetUpcomingCountByPropertyAsync(propertyId);

        public async Task<int> DeactivateExpiredAsync()
        {
            var db = unitOfWork.GetDatabaseContext();

            var toComplete = await db.PropertyReservations
                .Where(r => (r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid)
                         && r.DateOfOccupancyEnd <= DateTime.Now
                         && !r.IsDeleted)
                .Select(r => new
                {
                    r.Id,
                    r.ClientId,
                    r.ReservationNumber,
                    PropertyName = r.Property != null ? r.Property.Name : null,
                    PhotoUrl = db.Photos
                        .Where(p => p.PropertyId == r.PropertyId && !p.IsDeleted)
                        .Select(p => p.Url)
                        .FirstOrDefault()
                })
                .ToListAsync();

            var count = await unitOfWork.PropertyReservationRepository.DeactivateExpiredAsync();

            foreach (var r in toComplete)
            {
                try
                {
                    _publisher.Publish(new ReservationNotificationMessage
                    {
                        UserId            = r.ClientId,
                        ReservationId     = r.Id,
                        Title             = "Rezervacija završena",
                        Message           = $"Vaša rezervacija za \"{r.PropertyName}\" je završena. Ocijenite vaš boravak i iznajmljivača.",
                        ReservationNumber = r.ReservationNumber,
                        PropertyName      = r.PropertyName,
                        PropertyPhotoUrl  = r.PhotoUrl
                    }, "reservation.notification");
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex,
                        "Failed to publish completion notification for reservation {Id}.", r.Id);
                }
            }

            return count;
        }

        public async Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10)
            => await unitOfWork.PropertyReservationRepository.GetClientSummariesAsync(clientId, page, pageSize);

        public async Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10)
            => await unitOfWork.PropertyReservationRepository.GetRenterSummariesAsync(renterId, page, pageSize);
    }
}
