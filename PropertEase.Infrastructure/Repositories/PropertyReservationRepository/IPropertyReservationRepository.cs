using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;


namespace PropertEase.Infrastructure.Repositories.PropertyReservationRepository
{
    public interface IPropertyReservationRepository: IBaseRepository<PropertyReservation, int>
    {
        new Task<List<PropertyReservationDto>> GetAllAsync();
        Task<PropertyReservationDto> GetByIdAsync(int id);
        Task<List<PropertyReservationDto>> GetByNameAsync(string name);
        Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter);
        Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search);
        Task<List<PropertyReservationDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset);

        /// <summary>
        /// Returns the minimal data needed by the recommendation engine:
        /// total distinct client count, count of clients who reserved the target property,
        /// and a co-occurrence map (otherPropertyId → distinct client count).
        /// All computed in SQL — no full table load.
        /// </summary>
        Task<(int TotalClientCount, int PropertyClientCount, Dictionary<int, int> CoOccurrences)>
            GetRecommendationDataAsync(int propertyId);

        /// <summary>
        /// Sets IsActive = false for all non-deleted reservations whose end date has passed.
        /// Executed as a single SQL UPDATE — no rows are loaded into memory.
        /// </summary>
        Task<int> DeactivateExpiredAsync();

        Task<List<PropertyReservationDto>> GetForReportAsync(int? ownerId, DateTime? from, DateTime? to);

        Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10);
        Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10);

        /// <summary>
        /// Returns the count of non-deleted reservations whose end date is in the future (upcoming).
        /// </summary>
        Task<int> GetUpcomingCountByPropertyAsync(int propertyId);
    }
}
