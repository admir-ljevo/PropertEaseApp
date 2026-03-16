using PropertEase.Core.Dto.ReservationNotification;

namespace PropertEase.Infrastructure.Repositories.ReservationNotificationRepository
{
    public interface IReservationNotificationRepository
    {
        Task AddAsync(ReservationNotificationDto dto);
        Task<List<ReservationNotificationDto>> GetByUserAsync(int userId, int page, int pageSize);
        Task<int> GetUnseenCountAsync(int userId);
        Task MarkAllSeenAsync(int userId);
    }
}
