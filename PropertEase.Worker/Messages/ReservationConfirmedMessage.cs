namespace PropertEase.Worker.Messages;

public class ReservationConfirmedMessage : BaseMessage
{
    public int ReservationId { get; set; }
    public string ReservationNumber { get; set; } = string.Empty;
    public string ClientEmail { get; set; } = string.Empty;
    public string ClientFullName { get; set; } = string.Empty;
    public string PropertyName { get; set; } = string.Empty;
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
    public decimal TotalPrice { get; set; }
}
