using MobiFon.Core.Dto.ApplicationUser;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Notification
{
    public class NotificationDto: BaseDto
    {
        public string Name { get; set; }
        public int UserId { get; set; }
        public ApplicationUserDto User { get; set; }
        public string? Image { get; set; }
        public string Text { get; set; }
    }
}
