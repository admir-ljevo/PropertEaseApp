using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Reporting.Models;

namespace MobiFon.Infrastructure.Repositories.PropertyReservationRepository
{
    public interface IPropertyReservationRepository: IBaseRepository<PropertyReservation, int>
    {
        new Task<List<PropertyReservationDto>> GetAllAsync();
        Task<PropertyReservationDto> GetByIdAsync(int id);
        Task<List<PropertyReservationDto>> GetByNameAsync(string name);
        Task<List<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter);
        Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search);
        Task<List<PropertyReservationDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset);
    }
}
