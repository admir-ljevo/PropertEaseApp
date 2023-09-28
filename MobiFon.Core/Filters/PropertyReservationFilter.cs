﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Filters
{
    public class PropertyReservationFilter
    {
        public DateTime? DateOccupancyStarted { get; set; }
        public DateTime? DateOccupancyEnded { get; set; }
        public float? totalPriceFrom { get; set; }
        public float? totalPriceTo { get; set; }
        public int propertyTypeId { get; set; }
        public string? propertyName { get; set; }

        public bool? isActive { get; set; } 


    }
}
