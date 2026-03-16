using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Message;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Dto.Conversation
{
    public class ConversationDto: BaseDto
    {
        public PropertyDto? Property { get; set; }
        public int? PropertyId { get; set; }
        public ApplicationUserDto Client { get; set; }
        public int ClientId { get; set; }
        public ApplicationUserDto Renter { get; set; }
        public int RenterId { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastSent { get; set; }
        public int UnreadCount { get; set; }
        public ICollection<MessageDto> Messages { get; set; }
    }
}
