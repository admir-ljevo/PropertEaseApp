using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;
using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Entities
{
    public class Payment : BaseEntity
    {
        public int ClientId { get; set; }
        public ApplicationUser Client { get; set; }
        public int? ReservationId { get; set; }
        public PropertyReservation Reservation { get; set; }
        public string PayPalPaymentId { get; set; }
        public string PayPalPayerId { get; set; }
        public double Amount { get; set; }
        public string Currency { get; set; } = "USD";
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string? Description { get; set; }
    }
}
