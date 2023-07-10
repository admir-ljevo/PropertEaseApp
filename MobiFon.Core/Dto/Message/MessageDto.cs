
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Conversation;

namespace MobiFon.Core.Dto.Message
{
    public class MessageDto: BaseDto
    {
        public ApplicationUserDto Sender { get; set; }
        public int SenderId { get; set; }
        public ApplicationUserDto Recipient { get; set; }
        public int RecipientId { get; set; }
        public ConversationDto Conversation { get; set; }
        public int ConversationId { get; set; }
        public string Content { get; set; }
    }
}
