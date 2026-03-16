using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Entities;
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
    }
}
