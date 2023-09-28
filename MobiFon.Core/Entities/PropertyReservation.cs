using MobiFon.Core.Entities.Base;
using MobiFon.Core.Entities.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities
{
    public class PropertyReservation: BaseEntity
    {
        public Property Property { get; set; }
        public string ReservationNumber { get; set; }

        public int PropertyId { get; set; }
        public ApplicationUser Client { get; set; }
        public int ClientId { get; set; }
        public int NumberOfGuests { get; set; }
        public DateTime DateOfOccupancyStart { get; set; }  
        public DateTime DateOfOccupancyEnd { get; set; }  
        public int NumberOfDays { get; set; }
        public int NumberOfMonths { get; set; }
        public float TotalPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }  
        public bool IsActive { get; set; }  
        public string? Description { get;set; }

    }
}
