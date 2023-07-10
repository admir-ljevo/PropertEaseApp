using Microsoft.AspNetCore.Identity;
using MobiFon.Shared.Models;

namespace MobiFon.Services.AccessManager
{
    public interface IAccessManager
    {
        Task<LoginInformation> SignInAsync(string email, string password, bool rememberMe);
        Task<IdentityResult> ChangePassword(string currentPassword, string newPassword);
        Task ResetPassword(string email);
    }
}
