

using MobiFon.Core.Dto.ApplicationUser;

namespace MobiFon.Shared.Models
{
    public class LoginInformation
    {
        public ApplicationUserDto User { get; set; }
        public string Token { get; set; }
        public int UserId { get; set; }
        public string? Role { get; set; }
    }
}
