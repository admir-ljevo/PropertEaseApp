namespace PropertEase.Core.Dto.Payment
{
    public class PayForReservationDto
    {
        public int ReservationId { get; set; }
        public string PayPalPaymentId { get; set; } = string.Empty;
        public string PayPalPayerId { get; set; } = string.Empty;
        public double Amount { get; set; }
    }
}
