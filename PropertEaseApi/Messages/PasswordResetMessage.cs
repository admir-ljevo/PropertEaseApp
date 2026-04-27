namespace PropertEase.Api.Messages
{
    public class PasswordResetMessage
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Otp { get; set; } = string.Empty;
    }
}
