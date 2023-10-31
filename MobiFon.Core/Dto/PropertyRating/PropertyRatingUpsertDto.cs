using MobiFon.Core.Dto.ApplicationUser;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.PropertyRating
{
    public class PropertyRatingUpsertDto: BaseDto
    {
        public int PropertyId { get; set; }
        public int ReviewerId { get; set; }
        public string ReviewerName { get; set; }
        public double Rating { get; set; }
        public string Description { get; set; }
    }
}
