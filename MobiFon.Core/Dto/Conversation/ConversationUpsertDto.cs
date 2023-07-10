using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Property;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Conversation
{
    public class ConversationUpsertDto: BaseDto
    {
        public int PropertyId { get; set; }
        public int ClientId { get; set; }
        public int RenterId { get; set; }
    }
}
