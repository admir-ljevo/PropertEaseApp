using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;

namespace PropertEase.Core.Entities
{
    public class ReservationNotification : BaseEntity
    {
        public int UserId { get; set; }
        public ApplicationUser? User { get; set; }
        public int? ReservationId { get; set; }
        public PropertyReservation? Reservation { get; set; }
        public string Message { get; set; } = string.Empty;
        public bool IsSeen { get; set; } = false;
        public string? ReservationNumber { get; set; }
        public string? PropertyName { get; set; }
        public string? PropertyPhotoUrl { get; set; }
    }
}
