using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Filters
{
    public class PropertyReservationFilter
    {
        public DateTime? DateOccupancyStartedStart { get; set; }
        public DateTime? DateOccupancyStartedEnd { get; set; }

        public DateTime? DateOccupancyEnded { get; set; }
        public double? totalPriceFrom { get; set; }
        public double? totalPriceTo { get; set; }
        public int? propertyTypeId { get; set; }
        public int? propertyId { get; set; }
        public string? propertyName { get; set; }

        public int? renterId { get; set; }
        public int? clientId { get; set; }
        public bool? isActive { get; set; }

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
