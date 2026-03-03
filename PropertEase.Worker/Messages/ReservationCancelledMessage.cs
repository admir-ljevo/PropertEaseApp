namespace PropertEase.Worker.Messages;

public class ReservationCancelledMessage : BaseMessage
{
    public int ReservationId { get; set; }
    public string ReservationNumber { get; set; } = string.Empty;
    public string ClientEmail { get; set; } = string.Empty;
    public string ClientFullName { get; set; } = string.Empty;
    public string PropertyName { get; set; } = string.Empty;
    public string CancellationReason { get; set; } = string.Empty;
}
