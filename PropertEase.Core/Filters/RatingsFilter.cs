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
        public DateTime? CreatedFrom { get; set;}
        public DateTime? CreatedTo { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        /// <summary>"asc" = lowest first, "desc" = highest first, null = newest first</summary>
        public string? SortByRating { get; set; }
    }
}
