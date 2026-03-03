using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Message;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Conversation
{
    public class ConversationDto: BaseDto
    {
        public PropertyDto Property { get; set; }
        public int PropertyId { get; set; }
        public ApplicationUserDto Client { get; set; }
        public int ClientId { get; set; }
        public ApplicationUserDto Renter { get; set; }
        public int RenterId { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastSent { get; set; } 
        public ICollection<MessageDto> Messages { get; set; }
    }
}
