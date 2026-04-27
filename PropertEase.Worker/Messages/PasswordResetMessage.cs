namespace PropertEase.Worker.Messages;

public class PasswordResetMessage : BaseMessage
{
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
}
