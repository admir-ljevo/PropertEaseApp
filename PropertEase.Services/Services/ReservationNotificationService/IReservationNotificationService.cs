using PropertEase.Core.Dto.ReservationNotification;

namespace PropertEase.Services.Services.ReservationNotificationService
{
    public interface IReservationNotificationService
    {
        Task CreateAsync(ReservationNotificationDto dto);
        Task<List<ReservationNotificationDto>> GetByUserAsync(int userId, int page, int pageSize);
        Task<int> GetUnseenCountAsync(int userId);
        Task MarkAllSeenAsync(int userId);
    }
}
