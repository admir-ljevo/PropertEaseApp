using PropertEase.Core.Dto.Notification;
using PropertEase.Services.Services.BaseService;
using PropertEase.Core.Filters;

namespace PropertEase.Services.Services.NotificationService
{
    public interface INotificationService: IBaseService<NotificationDto>
    {
        Task<List<NotificationDto>> GetByNameAsync(string name);
        Task<PropertEase.Core.Dto.PagedResult<NotificationDto>> GetFiltered(NotificationFilter filter);

    }
}
