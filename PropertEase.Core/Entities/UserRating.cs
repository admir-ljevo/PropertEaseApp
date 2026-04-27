using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;

namespace PropertEase.Core.Entities
{
    public class UserRating : BaseEntity
    {
        public ApplicationUser Renter { get; set; }
        public int RenterId { get; set; }
        public ApplicationUser Reviewer { get; set; }
        public int ReviewerId { get; set; }
        public string ReviewerName { get; set; }
        public double Rating { get; set; }
        public string? Description { get; set; }
        public int? ReservationId { get; set; }
        public PropertyReservation? Reservation { get; set; }
    }
}
