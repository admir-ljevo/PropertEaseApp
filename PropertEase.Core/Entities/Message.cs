using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;

namespace PropertEase.Core.Entities
{
    public class Message: BaseEntity
    {
        public ApplicationUser Sender { get; set; }
        public int SenderId { get; set; }
        public ApplicationUser Recipient { get; set; }
        public int RecipientId { get; set; }
        public Conversation Conversation { get; set; }
        public int ConversationId { get; set; }
        public string Content { get; set; }
        public bool IsRead { get; set; }
    }
}
