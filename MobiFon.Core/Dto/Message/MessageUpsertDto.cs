using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Message
{
    public class MessageUpsertDto: BaseDto
    {
        public int SenderId { get; set; }
        public int RecipientId { get; set; }
        public int ConversationId { get; set; }
        public string Content { get; set; }

    }
}
