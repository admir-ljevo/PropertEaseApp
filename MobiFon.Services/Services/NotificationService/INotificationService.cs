using MobiFon.Core.Dto.Notification;
using MobiFon.Services.Services.BaseService;
using PropertEase.Core.Filters;

namespace MobiFon.Services.Services.NotificationService
{
    public interface INotificationService: IBaseService<NotificationDto>
    {
        Task<List<NotificationDto>> GetByNameAsync(string name);
        Task<List<NotificationDto>> GetFiltered(NotificationFilter filter);

    }
}
