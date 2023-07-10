using MobiFon.Core.Dto.Notification;
using MobiFon.Services.Services.BaseService;

namespace MobiFon.Services.Services.NotificationService
{
    public interface INotificationService: IBaseService<NotificationDto>
    {
        Task<List<NotificationDto>> GetByNameAsync(string name);

    }
}
