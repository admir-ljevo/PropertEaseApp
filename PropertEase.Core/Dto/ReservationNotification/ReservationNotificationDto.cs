namespace PropertEase.Core.Dto.ReservationNotification
{
    public class ReservationNotificationDto : BaseDto
    {
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public string Message { get; set; } = string.Empty;
        public bool IsSeen { get; set; }
        public string? ReservationNumber { get; set; }
        public string? PropertyName { get; set; }
        public string? PropertyPhotoUrl { get; set; }
    }
}
