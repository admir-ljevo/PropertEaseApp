using MobiFon.Core.Dto.Notification;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;

namespace MobiFon.Infrastructure.Repositories.NotificationRepository
{
    public interface INotificationRepository: IBaseRepository<Notification, int>
    {
        new Task<List<NotificationDto>> GetAllAsync();
        Task<NotificationDto> GetByIdAsync(int id);
        Task<List<NotificationDto>> GetFiltered(NotificationFilter filter);
        Task<List<NotificationDto>> GetByNameAsync(string name);    
    }
}
