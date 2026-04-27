namespace PropertEase.Worker.Messages;

public class ReservationCancelledMessage : BaseMessage
{
    public int ReservationId { get; set; }
    public string ReservationNumber { get; set; } = string.Empty;
    public string PropertyName { get; set; } = string.Empty;
    public string CancellationReason { get; set; } = string.Empty;
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
    public decimal TotalPrice { get; set; }
    public string? PropertyPhotoUrl { get; set; }

    public string ActorFullName { get; set; } = string.Empty;

    public int ClientUserId { get; set; }
    public string ClientEmail { get; set; } = string.Empty;
    public string ClientFullName { get; set; } = string.Empty;

    public int? RenterUserId { get; set; }
    public string RenterEmail { get; set; } = string.Empty;
    public string RenterFullName { get; set; } = string.Empty;
}
