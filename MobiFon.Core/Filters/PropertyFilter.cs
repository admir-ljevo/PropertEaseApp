using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.City;
using MobiFon.Core.Dto.PropertyType;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Filters
{
    public class PropertyFilter
    {
        public string? Name { get; set; }
        public int? PropertyTypeId { get; set; }
        public int? CityId { get; set; }
        public int? ApplicationUserId { get; set; }
        public string? Address { get; set; }
        public string? Description { get; set; }
        public int? NumberOfRoomsFrom { get; set; }
        public int? NumberOfRoomsTo { get; set; }
        public int? NumberOfBathroomsFrom { get; set; }
        public int? NumberOfBathroomsTo { get; set; }
        public int? SquareMetersFrom { get; set; }
        public int? SquareMetersTo { get; set; }
        public int? CapacityFrom { get; set; }
        public int? CapacityTo { get; set; }
       
        public float? PriceFrom { get; set; }
        public float? PriceTo { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }
        public bool? IsAvailable { get; set; }

        public bool HasWiFi { get; set; }
        public bool IsFurnished { get; set; }
        public bool HasBalcony { get; set; }
        public int? MinimalNumberOfGarages { get; set; }
        public bool HasPool { get; set; }
        public bool HasAirCondition { get; set; }
        public bool HasAlarm { get; set; }
        public bool HasCableTV { get; set; }
        public bool HasOwnHeatingSystem { get; set; }
        public int? GardenSize { get; set; }
        public int? GarageSizeFrom { get; set; }
        public int? GarageSizeTo { get; set; }
        public int? ParkingSizeFrom { get; set; }
        public int? ParkingSizeTo { get; set; }
    }
}
