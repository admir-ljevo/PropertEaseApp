using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Services.Services.BaseService;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyReservationService
{
    public interface IPropertyReservationService: IBaseService<PropertyReservationDto>
    {
        public Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter);
        public Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search);
        public Task<int> DeactivateExpiredAsync();
        public Task<int> GetUpcomingCountByPropertyAsync(int propertyId);
        public Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10);
        public Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10);
        public Task<PropertyReservationDto> UpdateWithNotificationAsync(int id, PropertyReservationUpsertDto dto, int? actorId = null);
        public Task<PropertyReservationDto> ConfirmReservationAsync(int id, int actorId);
        /// <summary>
        /// Synchronises <see cref="PropertEase.Core.Entities.Property.IsAvailable"/> with the
        /// current set of active reservations for the given property.
        /// </summary>
        public Task SyncPropertyAvailabilityAsync(int propertyId);
    }
}
