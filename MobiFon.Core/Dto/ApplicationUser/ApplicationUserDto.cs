using Microsoft.AspNetCore.Identity;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Entities;
using MobiFon.Core.Entities.Base;
using MobiFon.Core.Entities.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.ApplicationUser
{
    public class ApplicationUserDto : IdentityUser<int>, IBaseEntity
    {
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
        public bool Active { get; set; }
        public int PersonId { get; set; }
        public PersonDto Person { get; set; }
        public bool IsAdministrator { get; set; }
        public bool IsEmployee { get; set; }
        public bool IsClient { get; set; }
        public bool IsCompanyOwner { get; set; }
        public ICollection<ApplicationUserRoleDto> UserRoles { get; set; }

    }
}
