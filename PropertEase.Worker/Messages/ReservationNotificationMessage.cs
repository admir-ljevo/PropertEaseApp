namespace PropertEase.Worker.Messages;

public class ReservationNotificationMessage
{
    public int UserId { get; set; }
    public int? ReservationId { get; set; }
    public string? Title { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? ReservationNumber { get; set; }
    public string? PropertyName { get; set; }
    public string? PropertyPhotoUrl { get; set; }
}
