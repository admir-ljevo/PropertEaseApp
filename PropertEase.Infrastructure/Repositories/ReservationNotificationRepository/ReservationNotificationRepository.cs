using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.ReservationNotification;
using PropertEase.Core.Entities;

namespace PropertEase.Infrastructure.Repositories.ReservationNotificationRepository
{
    public class ReservationNotificationRepository : IReservationNotificationRepository
    {
        private readonly DatabaseContext _db;

        public ReservationNotificationRepository(DatabaseContext db)
        {
            _db = db;
        }

        public async Task AddAsync(ReservationNotificationDto dto)
        {
            var entity = new ReservationNotification
            {
                UserId = dto.UserId,
                ReservationId = dto.ReservationId,
                Message = dto.Message,
                IsSeen = false,
                ReservationNumber = dto.ReservationNumber,
                PropertyName = dto.PropertyName,
                PropertyPhotoUrl = dto.PropertyPhotoUrl,
                CreatedAt = DateTime.Now,
                IsDeleted = false
            };
            _db.ReservationNotifications.Add(entity);
            await _db.SaveChangesAsync();
        }

        public async Task<List<ReservationNotificationDto>> GetByUserAsync(int userId, int page, int pageSize)
        {
            return await _db.ReservationNotifications
                .Where(n => n.UserId == userId && !n.IsDeleted)
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new ReservationNotificationDto
                {
                    Id = n.Id,
                    UserId = n.UserId,
                    ReservationId = n.ReservationId,
                    Message = n.Message,
                    IsSeen = n.IsSeen,
                    ReservationNumber = n.ReservationNumber,
                    PropertyName = n.PropertyName,
                    PropertyPhotoUrl = n.PropertyPhotoUrl,
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();
        }

        public async Task<int> GetUnseenCountAsync(int userId)
        {
            return await _db.ReservationNotifications
                .CountAsync(n => n.UserId == userId && !n.IsSeen && !n.IsDeleted);
        }

        public async Task MarkAllSeenAsync(int userId)
        {
            await _db.ReservationNotifications
                .Where(n => n.UserId == userId && !n.IsSeen && !n.IsDeleted)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsSeen, true));
        }
    }
}
