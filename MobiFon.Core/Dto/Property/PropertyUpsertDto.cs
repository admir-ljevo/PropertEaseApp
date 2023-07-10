using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.City;
using MobiFon.Core.Dto.PropertyType;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Property
{
    public class PropertyUpsertDto: BaseDto
    {
        public string Name { get; set; }
        public int PropertyTypeId { get; set; }
        public int CityId { get; set; }
        public int ApplicationUserId { get; set; }
        public string Address { get; set; }
        public string Description { get; set; }
        public int NumberOfRooms { get; set; }
        public int NumberOfBathrooms { get; set; }
        public int SquareMeters { get; set; }
        public int Capacity { get; set; }
        public float? MonthlyPrice { get; set; }
        public float? DailyPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }
        public bool HasWiFi { get; set; }
        public bool IsFurnished { get; set; }
        public bool HasBalcony { get; set; }
        public int NumberOfGarages { get; set; }
        public bool HasPool { get; set; }
        public bool HasAirCondition { get; set; }
        public bool HasAlarm { get; set; }
        public bool HasCableTV { get; set; }
        public bool HasOwnHeatingSystem { get; set; }
        public int GardenSize { get; set; }
        public int GarageSize { get; set; }
        public int ParkingSize { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double AverageRating { get; set; }
        public bool IsAvailable { get; set; }

    }
}
