namespace MobiFon.Services.Reports;

public interface IReportService
{
    Task<byte[]> GenerateReservationReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null);
    Task<byte[]> GenerateRevenueReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null);
    Task<byte[]> GeneratePaymentReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null);
}
