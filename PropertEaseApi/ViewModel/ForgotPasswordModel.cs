using System.ComponentModel.DataAnnotations;

namespace PropertEase.ViewModel
{
    public class ForgotPasswordModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
