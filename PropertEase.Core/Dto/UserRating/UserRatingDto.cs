using PropertEase.Core.Dto.ApplicationUser;

namespace PropertEase.Core.Dto.UserRating
{
    public class UserRatingDto : BaseDto
    {
        public int RenterId { get; set; }
        public ApplicationUserDto? Renter { get; set; }
        public int ReviewerId { get; set; }
        public ApplicationUserDto? Reviewer { get; set; }
        public string ReviewerName { get; set; } = string.Empty;
        public double Rating { get; set; }
        public string? Description { get; set; }
        public int? ReservationId { get; set; }
    }
}
