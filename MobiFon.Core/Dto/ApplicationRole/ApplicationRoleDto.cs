using Microsoft.AspNetCore.Identity;
using MobiFon.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.ApplicationRole
{
    public class ApplicationRoleDto: IdentityRole<int>, IBaseEntity
    {
        public int? RoleLevel { get; set; }
        public string Name { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
        public ICollection<ApplicationUserRoleDto> UserRoles { get; set; }
    }
}
