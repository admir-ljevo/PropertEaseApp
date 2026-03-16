

using PropertEase.Core.Dto.ApplicationUser;

namespace PropertEase.Shared.Models
{
    public class LoginInformation
    {
        public ApplicationUserDto User { get; set; }
        public string Token { get; set; }
        public int UserId { get; set; }
        public string? Role { get; set; }
        public int? RoleId { get; set; }
        public bool IsRenter { get; set; }
    }
}
