namespace PropertEase.Core.Dto.Payment
{
    public class PayPalConfigDto
    {
        public string ClientId { get; set; } = string.Empty;
        public bool SandboxMode { get; set; }
    }
}
