using Microsoft.AspNetCore.Identity;
using PropertEase.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Entities.Identity
{
    public class ApplicationUser: IdentityUser<int>, IBaseEntity
    {
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
        public bool Active { get; set; }
        public Person Person { get; set; }

        public ICollection<ApplicationUserRole> Roles { get; set; }

    }
}
