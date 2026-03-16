using PropertEase.Shared.Models;
using System.Security.Claims;


namespace PropertEase.Shared.Services.LoggedUserData
{
    public interface ILoggedUserData
    {
        UserDataModel GetUserData(ClaimsPrincipal claimsPrincipal);

    }
}
