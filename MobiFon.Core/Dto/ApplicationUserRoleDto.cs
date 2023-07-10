using MobiFon.Core.Dto.ApplicationRole;
using MobiFon.Core.Dto.ApplicationUser;

namespace MobiFon.Core.Dto
{
    public class ApplicationUserRoleDto: BaseDto
    {
        public ApplicationUserDto User { get; set; }
        public ApplicationRoleDto Role { get; set; }
        public int UserId { get; set; }
        public int RoleId { get; set; }
    }
}
