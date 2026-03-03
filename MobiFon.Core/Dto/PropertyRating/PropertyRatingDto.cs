using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Property;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.PropertyRating
{
    public class PropertyRatingDto: BaseDto
    {
        public PropertyDto Property { get; set; }
        public int PropertyId { get; set; }
        public ApplicationUserDto Reviewer { get; set; }
        public int ReviewerId { get; set; }
        public string ReviewerName { get; set; }
        public double Rating { get; set; }
        public string Description { get; set; }
    }
}
