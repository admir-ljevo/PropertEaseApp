﻿using Microsoft.AspNetCore.Identity;
using MobiFon.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities.Identity
{
    public class ApplicationUserClaim : IdentityUserClaim<int>, IBaseEntity
    {
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public bool IsDeleted { get; set; }
    }
}
