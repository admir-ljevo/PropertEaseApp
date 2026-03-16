using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Property;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Dto.Conversation
{
    public class ConversationUpsertDto: BaseDto
    {
        public int? PropertyId { get; set; }
        public int ClientId { get; set; }
        public int RenterId { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastSent { get; set; }
    }
}
