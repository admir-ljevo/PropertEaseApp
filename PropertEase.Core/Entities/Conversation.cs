using PropertEase.Core.Dto.Message;
using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;


namespace PropertEase.Core.Entities
{
    public class Conversation : BaseEntity
    {
        public Property? Property { get; set; }
        public int? PropertyId { get; set; }
        public ApplicationUser Client { get; set; }
        public int ClientId { get; set; }
        public ApplicationUser Renter { get; set; }
        public int RenterId { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastSent { get; set; }
        public List<Message> Messages { get; set; }
    }
}
