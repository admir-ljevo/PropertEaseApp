using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Dto.PropertyReservation;

namespace PropertEase.Services.Services.PaymentService
{
    public interface IPaymentService
    {
        Task<PropertyReservationDto> CompleteReservationAsync(CompleteReservationPaymentDto dto);
        object GetPayPalConfig();
        Task RefundReservationAsync(int reservationId, bool enforceSevenDayRule);
    }
}
