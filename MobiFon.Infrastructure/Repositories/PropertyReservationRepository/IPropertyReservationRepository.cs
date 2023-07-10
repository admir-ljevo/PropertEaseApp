using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.PropertyReservationRepository
{
    public interface IPropertyReservationRepository: IBaseRepository<PropertyReservation, int>
    {
        new Task<List<PropertyReservationDto>> GetAllAsync();
        Task<PropertyReservationDto> GetByIdAsync(int id);
        Task<List<PropertyReservationDto>> GetByNameAsync(string name);
        Task<List<PropertyReservationDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset);
    }
}
