namespace PropertEase.Worker.Messages;

public class NotificationMessage : BaseMessage
{
    public int UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? RedirectUrl { get; set; }
}
