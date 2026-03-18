using Microsoft.AspNetCore.Identity;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Entities;
using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Dto.ApplicationUser
{
    public class ApplicationUserDto : IdentityUser<int>, IBaseEntity
    {
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
        public bool Active { get; set; }
        public int PersonId { get; set; }
        public PersonDto Person { get; set; }
        public ICollection<ApplicationUserRoleDto>? UserRoles { get; set; }

    }
}
