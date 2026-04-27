using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Dto.Payment
{
    public class PaymentDto : BaseDto
    {
        public int ClientId { get; set; }
        public int? ReservationId { get; set; }
        public string PayPalPaymentId { get; set; }
        public string PayPalPayerId { get; set; }
        public double Amount { get; set; }
        public string Currency { get; set; }
        public PaymentStatus Status { get; set; }
        public string? Description { get; set; }
    }
}
