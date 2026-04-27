using Microsoft.AspNetCore.Identity;
using PropertEase.Shared.Models;

namespace PropertEase.Services.AccessManager
{
    public interface IAccessManager
    {
        Task<LoginInformation> SignInAsync(string email, string password, bool rememberMe);
        Task<IdentityResult> ChangePassword(string currentPassword, string newPassword, string userId);
        Task ForgotPasswordAsync(string email);
        Task<IdentityResult> ResetPasswordAsync(string email, string otp, string newPassword);
        Task<IdentityResult> AdminResetPassword(string userId, string newPassword);
    }
}
