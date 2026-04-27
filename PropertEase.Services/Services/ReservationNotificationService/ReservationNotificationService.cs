using PropertEase.Core.Dto.ReservationNotification;
using PropertEase.Infrastructure.Repositories.ReservationNotificationRepository;

namespace PropertEase.Services.Services.ReservationNotificationService
{
    public class ReservationNotificationService : IReservationNotificationService
    {
        private readonly IReservationNotificationRepository _repo;

        public ReservationNotificationService(IReservationNotificationRepository repo)
        {
            _repo = repo;
        }

        public Task CreateAsync(ReservationNotificationDto dto) => _repo.AddAsync(dto);

        public Task<List<ReservationNotificationDto>> GetByUserAsync(int userId, int page, int pageSize)
            => _repo.GetByUserAsync(userId, page, pageSize);

        public Task<int> GetUnseenCountAsync(int userId) => _repo.GetUnseenCountAsync(userId);

        public Task MarkAllSeenAsync(int userId) => _repo.MarkAllSeenAsync(userId);

        public Task MarkSeenAsync(int notificationId) => _repo.MarkSeenAsync(notificationId);
    }
}
