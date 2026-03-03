namespace PropertEase.Worker.Messages;

public abstract class BaseMessage
{
    public Guid MessageId { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string MessageType => GetType().Name;
}
