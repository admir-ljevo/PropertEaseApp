using MobiFon.Core.Entities.Base;
using MobiFon.Core.Entities.Identity;

namespace MobiFon.Core.Entities
{
    public class PropertyRating: BaseEntity
    {
        public Property Property { get; set; }
        public int PropertyId { get; set; }
        public ApplicationUser Reviewer { get; set; }
        public int ReviewerId { get; set; }
        public string ReviewerName { get; set; }
        public double Rating { get; set; }
        public string Description { get; set; }

    }
}