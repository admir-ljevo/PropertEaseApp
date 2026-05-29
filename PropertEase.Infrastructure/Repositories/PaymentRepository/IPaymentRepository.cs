using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.PaymentRepository
{
    public interface IPaymentRepository : IBaseRepository<Payment, int>
    {
        Task<Payment?> GetByReservationIdAsync(int reservationId);
        Task<List<Payment>> GetForReportAsync(int? ownerId, DateTime? from, DateTime? to);
    }
}
