using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Notification
{
    public class NotificationUpsertDto: BaseDto
    {
        public string Name { get; set; }
        public int UserId { get; set; }
        public string? Image { get; set; }
        public byte[]? ImageBytes { get; set; }

        public string Text { get; set; }
        public IFormFile? File { get; set; }
    }
}
