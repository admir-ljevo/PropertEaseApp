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

        public PropertyReservationController(
            IPropertyReservationService baseService,
            IMapper mapper)
            : base(baseService, mapper)
        {
            _reservationService = baseService;
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] PropertyReservationFilter filter)
        {
            var propertyReservations = await _reservationService.GetFiltered(filter);
            return Ok(propertyReservations);
        }

        [HttpGet("client/{clientId}/summary")]
        public async Task<IActionResult> GetClientSummaries(int clientId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var result = await _reservationService.GetClientSummariesAsync(clientId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("renter/{renterId}/summary")]
        public async Task<IActionResult> GetRenterSummaries(int renterId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var result = await _reservationService.GetRenterSummariesAsync(renterId, page, pageSize);
            return Ok(result);
        }

        [HttpPut("{id}")]
        public override async Task<PropertyReservationDto> Put(int id, [FromBody] PropertyReservationUpsertDto dto)
        {
            var actorId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : (int?)null;
            return await _reservationService.UpdateWithNotificationAsync(id, dto, actorId);
        }

        [HttpPost("{id}/confirm")]
        [Authorize(Roles = AppRoles.Renter + "," + AppRoles.Admin)]
        public async Task<IActionResult> Confirm(int id)
        {
            var actorId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
            var result = await _reservationService.ConfirmReservationAsync(id, actorId);
            return Ok(result);
        }
    }
}
