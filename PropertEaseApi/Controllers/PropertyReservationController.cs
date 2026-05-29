using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.PropertyReservationService;
using PropertEase.Core.Filters;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers
{
    [Authorize]
    public class PropertyReservationController : BaseController<PropertyReservationDto, PropertyReservationUpsertDto, PropertyReservationUpsertDto, BaseSearchObject>
    {
        private readonly IPropertyReservationService _reservationService;
        private readonly IMapper _mapper;

        public PropertyReservationController(
            IPropertyReservationService baseService,
            IMapper mapper)
            : base(baseService, mapper)
        {
            _reservationService = baseService;
            _mapper = mapper;
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyReservationFilter filter)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;

            if (!User.IsInRole(AppRoles.Admin))
            {
                if (User.IsInRole(AppRoles.Client))
                {
                    if (filter.clientId.HasValue && filter.clientId != callerId)
                        return Forbid();
                    filter.clientId = callerId;
                }
                else if (User.IsInRole(AppRoles.Renter))
                {
                    if (filter.renterId.HasValue && filter.renterId != callerId)
                        return Forbid();
                    filter.renterId = callerId;
                }
            }

            var propertyReservations = await _reservationService.GetFiltered(filter);
            return Ok(propertyReservations);
        }

        [Authorize(Roles = AppRoles.Admin + "," + AppRoles.Renter + "," + AppRoles.Client)]
        [HttpGet("client/{clientId}/summary")]
        public async Task<IActionResult> GetClientSummaries(int clientId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;

            if (!User.IsInRole(AppRoles.Admin) && User.IsInRole(AppRoles.Client) && callerId != clientId)
                return Forbid();

            int? renterId = null;
            if (!User.IsInRole(AppRoles.Admin) && User.IsInRole(AppRoles.Renter))
                renterId = callerId;

            var result = await _reservationService.GetClientSummariesAsync(clientId, page, pageSize, renterId);
            return Ok(result);
        }

        [Authorize(Roles = AppRoles.Admin + "," + AppRoles.Renter)]
        [HttpGet("renter/{renterId}/summary")]
        public async Task<IActionResult> GetRenterSummaries(int renterId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            if (!User.IsInRole(AppRoles.Admin))
            {
                var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
                if (callerId != renterId)
                    return Forbid();
            }

            var result = await _reservationService.GetRenterSummariesAsync(renterId, page, pageSize);
            return Ok(result);
        }

        [NonAction] public override Task<List<PropertyReservationDto>> Get(int page = 1, int pageSize = 20) => throw new NotSupportedException();
        [NonAction] public override Task<PropertyReservationDto> Get(int id) => throw new NotSupportedException();
        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<IActionResult> Delete(int id)
        {
            await _reservationService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(int id)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
            var reservation = await _reservationService.GetByIdAsync(id);
            if (reservation == null) return NotFound();

            if (!User.IsInRole(AppRoles.Admin))
            {
                if (User.IsInRole(AppRoles.Client) && reservation.ClientId != callerId)
                    return Forbid();
                if (User.IsInRole(AppRoles.Renter) && reservation.RenterId != callerId)
                    return Forbid();
            }

            return Ok(reservation);
        }
        [NonAction]
        public override Task<PropertyReservationDto> Post(PropertyReservationUpsertDto insertEntity) => base.Post(insertEntity);

        [Authorize(Roles = AppRoles.Client)]
        [HttpPost]
        public async Task<IActionResult> CreateReservation([FromBody] PropertyReservationUpsertDto dto)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
            var reservationDto = _mapper.Map<PropertyReservationDto>(dto);
            reservationDto.ClientId = callerId;
            var result = await _reservationService.AddAsync(reservationDto);
            return Ok(result);
        }

        [NonAction]
        public override Task<PropertyReservationDto> Put(int id, PropertyReservationUpsertDto dto) => base.Put(id, dto);

        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateReservation(int id, [FromBody] PropertyReservationUpsertDto dto)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;

            if (!User.IsInRole(AppRoles.Admin))
            {
                var reservation = await _reservationService.GetByIdAsync(id);
                if (reservation == null)
                    throw new KeyNotFoundException($"Reservation {id} not found.");

                if (User.IsInRole(AppRoles.Client) && reservation.ClientId != callerId)
                    throw new UnauthorizedAccessException();

                if (User.IsInRole(AppRoles.Renter) && reservation.RenterId != callerId)
                    throw new UnauthorizedAccessException();
            }

            var result = await _reservationService.UpdateWithNotificationAsync(id, dto, callerId);
            return Ok(result);
        }

        [HttpGet("price-preview")]
        [Authorize]
        public async Task<IActionResult> PricePreview(
            [FromQuery] int propertyId,
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate)
        {
            if (startDate >= endDate)
                return BadRequest("Datum odlaska mora biti poslije datuma dolaska.");
            try
            {
                var (totalPrice, numberOfDays, numberOfMonths) =
                    await _reservationService.CalculatePriceAsync(propertyId, startDate, endDate);
                return Ok(new { totalPrice, numberOfDays, numberOfMonths });
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpGet("availability/{propertyId}")]
        [Authorize]
        public async Task<IActionResult> GetAvailability(int propertyId)
        {
            var ranges = await _reservationService.GetOccupiedRangesAsync(propertyId);
            var result = ranges.Select(r => new { start = r.Start, end = r.End });
            return Ok(result);
        }

        [HttpPost("{id}/confirm")]
        [Authorize(Roles = AppRoles.Renter + "," + AppRoles.Admin)]
        public async Task<IActionResult> Confirm(int id)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;

            if (!User.IsInRole(AppRoles.Admin) && User.IsInRole(AppRoles.Renter))
            {
                var reservation = await _reservationService.GetByIdAsync(id);
                if (reservation == null || reservation.RenterId != callerId)
                    return Forbid();
            }

            var result = await _reservationService.ConfirmReservationAsync(id, callerId);
            return Ok(result);
        }
    }
}
