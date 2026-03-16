
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Conversation;

namespace PropertEase.Core.Dto.Message
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
        public bool IsRead { get; set; }
    }
}
