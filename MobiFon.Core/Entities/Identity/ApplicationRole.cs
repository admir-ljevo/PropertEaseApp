using Microsoft.AspNetCore.Identity;
using MobiFon.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities.Identity
{
    public class ApplicationRole : IdentityRole<int>, IBaseEntity
    {
        public int? RoleLevel { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
        public ICollection<ApplicationUserRole> Roles { get; set; }
    }
}
