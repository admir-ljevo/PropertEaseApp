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
        Task<PropertEase.Core.Dto.PagedResult<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter);
        Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search);
        Task<(int TotalClientCount, int PropertyClientCount, Dictionary<int, int> CoOccurrences)>
            GetRecommendationDataAsync(int propertyId);

    
        Task<int> DeactivateExpiredAsync();

        Task<List<PropertyReservationDto>> GetForReportAsync(int? ownerId, DateTime? from, DateTime? to);

        Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetClientSummariesAsync(int clientId, int page = 1, int pageSize = 10);
        Task<PropertEase.Core.Dto.PagedResult<ReservationSummaryDto>> GetRenterSummariesAsync(int renterId, int page = 1, int pageSize = 10);

        Task<int> GetUpcomingCountByPropertyAsync(int propertyId);
    }
}
