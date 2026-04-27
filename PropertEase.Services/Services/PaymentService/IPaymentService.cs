using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Dto.PropertyReservation;

namespace PropertEase.Services.Services.PaymentService
{
    public interface IPaymentService
    {
        Task<(string PaymentId, string ApprovalUrl)> CreatePayPalPaymentAsync(decimal amount);
        Task<(string PaymentId, string ApprovalUrl)> CreatePayPalPaymentForReservationAsync(int reservationId);
        Task<PropertyReservationDto> CompleteReservationAsync(CompleteReservationPaymentDto dto);
        Task<PropertyReservationDto> PayForReservationAsync(PayForReservationDto dto, int callerId);
        PayPalConfigDto GetPayPalConfig();
        Task RefundReservationAsync(int reservationId, bool enforceSevenDayRule, int? actorId = null, string? reason = null);
    }
}
