using Microsoft.AspNetCore.Identity;
using PropertEase.Shared.Models;

namespace PropertEase.Services.AccessManager
{
    public interface IAccessManager
    {
        Task<LoginInformation> SignInAsync(string email, string password, bool rememberMe);
        Task<IdentityResult> ChangePassword(string currentPassword, string newPassword, string userId);
        Task ResetPassword(string email);
        Task<IdentityResult> AdminResetPassword(string userId, string newPassword);
    }
}
