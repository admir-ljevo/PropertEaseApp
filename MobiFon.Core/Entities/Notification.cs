using MobiFon.Core.Entities.Base;
using MobiFon.Core.Entities.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities
{
    public class Notification: BaseEntity
    {
        public string Name { get; set; }
        public int UserId { get; set; }
        public ApplicationUser User { get; set; }
        public string? Image { get; set; }
        public string Text { get; set; }
    }
}
