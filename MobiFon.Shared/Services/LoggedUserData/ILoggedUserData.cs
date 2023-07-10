using MobiFon.Shared.Models;
using System.Security.Claims;


namespace MobiFon.Shared.Services.LoggedUserData
{
    public interface ILoggedUserData
    {
        UserDataModel GetUserData(ClaimsPrincipal claimsPrincipal);

    }
}
