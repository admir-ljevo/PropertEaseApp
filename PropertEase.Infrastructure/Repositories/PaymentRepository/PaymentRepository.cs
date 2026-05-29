using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Entities;
using PropertEase.Core.Enumerations;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.PaymentRepository
{
    public class PaymentRepository : BaseRepository<Payment, int>, IPaymentRepository
    {
        private readonly DatabaseContext _db;

        public PaymentRepository(IMapper mapper, DatabaseContext databaseContext)
            : base(mapper, databaseContext)
        {
            _db = databaseContext;
        }

        public async Task<Payment?> GetByReservationIdAsync(int reservationId)
        {
            return await _db.Payments
                .Where(p => p.ReservationId == reservationId && !p.IsDeleted)
                .OrderByDescending(p => p.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<List<Payment>> GetForReportAsync(int? ownerId, DateTime? from, DateTime? to)
        {
            var query = _db.Payments
                .AsNoTracking()
                .Include(p => p.Reservation).ThenInclude(r => r.Property)
                .Include(p => p.Client).ThenInclude(u => u.Person)
                .Where(p => !p.IsDeleted);

            if (ownerId.HasValue)
                query = query.Where(p => p.Reservation != null
                    && p.Reservation.Property.ApplicationUserId == ownerId.Value);

            if (from.HasValue)
                query = query.Where(p => p.CreatedAt >= from.Value);

            if (to.HasValue)
                query = query.Where(p => p.CreatedAt <= to.Value);

            return await query.OrderByDescending(p => p.CreatedAt).ToListAsync();
        }
    }
}
