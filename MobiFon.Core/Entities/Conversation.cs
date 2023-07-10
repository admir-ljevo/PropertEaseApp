using MobiFon.Core.Entities.Base;
using MobiFon.Core.Entities.Identity;


namespace MobiFon.Core.Entities
{
    public class Conversation : BaseEntity
    {
        public Property Property { get; set; }
        public int PropertyId { get; set; }
        public ApplicationUser Client { get; set; }
        public int ClientId { get; set; }
        public ApplicationUser Renter { get; set; }
        public int RenterId { get; set; }
        public List<Message> Messages { get; set; }
    }
}
