namespace PropertEase.Core.Dto.UserRating
{
    public class UserRatingUpsertDto : BaseDto
    {
        public int RenterId { get; set; }
        public int ReviewerId { get; set; }
        public string ReviewerName { get; set; } = string.Empty;
        public double Rating { get; set; }
        public string? Description { get; set; }
    }
}
