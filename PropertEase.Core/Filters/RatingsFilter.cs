using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Filters
{
    public class RatingsFilter
    {
        public int? PropertyId { get; set; }
        public int? ReviewerId { get; set; }
        public int? ReservationId { get; set; }
        public DateTime? CreatedFrom { get; set;}
        public DateTime? CreatedTo { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? SortByRating { get; set; }
    }
}
