using PropertEase.Core.Dto.Notification;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;

namespace PropertEase.Infrastructure.Repositories.NotificationRepository
{
    public interface INotificationRepository: IBaseRepository<Notification, int>
    {
        new Task<List<NotificationDto>> GetAllAsync();
        Task<NotificationDto> GetByIdAsync(int id);
        Task<PropertEase.Core.Dto.PagedResult<NotificationDto>> GetFiltered(NotificationFilter filter);
        Task<List<NotificationDto>> GetByNameAsync(string name);    
    }
}
