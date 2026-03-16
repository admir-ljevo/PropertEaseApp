using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.SearchObjects;
using PropertEase.Infrastructure;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Services.Services.PropertyReservationService;
using PropertEase.Core.Filters;

namespace PropertEase.Controllers
{
    public class PropertyReservationController : BaseController<PropertyReservationDto, PropertyReservationUpsertDto, PropertyReservationUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyReservationService propertyReservationService;
        private readonly IRabbitMQPublisher _publisher;
        private readonly DatabaseContext _db;

        public PropertyReservationController(
            IPropertyReservationService baseService,
            IMapper mapper,
            IRabbitMQPublisher publisher,
            DatabaseContext db)
            : base(baseService, mapper)
        {
            propertyReservationService = baseService;
            _publisher = publisher;
            _db = db;
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyReservationFilter filter)
        {
            try
            {
                var propertyReservations = await propertyReservationService.GetFiltered(filter);
                return Ok(propertyReservations);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpGet("client/{clientId}/summary")]
        public async Task<IActionResult> GetClientSummaries(int clientId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                var result = await propertyReservationService.GetClientSummariesAsync(clientId, page, pageSize);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpGet("renter/{renterId}/summary")]
        public async Task<IActionResult> GetRenterSummaries(int renterId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                var result = await propertyReservationService.GetRenterSummariesAsync(renterId, page, pageSize);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpPost]
        public override async Task<PropertyReservationDto> Post([FromBody] PropertyReservationUpsertDto insertEntity)
        {
            try
            {
                return await base.Post(insertEntity);
            }
            catch (InvalidOperationException ex)
            {
                HttpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
                await HttpContext.Response.WriteAsJsonAsync(new { message = ex.Message });
                return null!;
            }
        }

        [HttpPut("{id}")]
        public override async Task<PropertyReservationDto> Put(int id, [FromBody] PropertyReservationUpsertDto updateEntity)
        {
            var existing = await propertyReservationService.GetByIdAsync(id);
            if (existing == null)
                throw new Exception($"Reservation {id} not found");

            existing.NumberOfGuests = updateEntity.NumberOfGuests;
            existing.DateOfOccupancyStart = updateEntity.DateOfOccupancyStart;
            existing.DateOfOccupancyEnd = updateEntity.DateOfOccupancyEnd;
            existing.IsActive = updateEntity.IsActive;
            existing.Description = updateEntity.Description;
            existing.TotalPrice = updateEntity.TotalPrice;
            existing.IsMonthly = updateEntity.IsMonthly;
            existing.IsDaily = updateEntity.IsDaily;

            var days = (int)(existing.DateOfOccupancyEnd - existing.DateOfOccupancyStart).TotalDays;
            existing.NumberOfDays = Math.Max(days, 0);
            existing.NumberOfMonths = (int)(Math.Max(days, 0) / 30.0);

            var result = await propertyReservationService.UpdateAsync(existing);

            // Notify client that reservation was updated (best-effort via RabbitMQ)
            try
            {
                var prop = await _db.Properties
                    .AsNoTracking()
                    .Where(p => p.Id == existing.PropertyId && !p.IsDeleted)
                    .Select(p => new
                    {
                        p.Name,
                        PhotoUrl = p.Images.Where(i => !i.IsDeleted).Select(i => i.Url).FirstOrDefault()
                    })
                    .FirstOrDefaultAsync();

                _publisher.Publish(new ReservationNotificationMessage
                {
                    UserId = existing.ClientId,
                    ReservationId = id,
                    Message = "Vaša rezervacija je ažurirana",
                    ReservationNumber = existing.ReservationNumber,
                    PropertyName = prop?.Name,
                    PropertyPhotoUrl = prop?.PhotoUrl
                }, "reservation.notification");
            }
            catch { /* notification failure is non-critical */ }

            return result;
        }
    }
}
