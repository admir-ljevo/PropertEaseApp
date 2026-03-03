namespace MobiFon.Core.Dto.PropertyReservation
{
    public class PropertyReservationUpsertDto: BaseDto
    {
        public int PropertyId { get; set; }
        public string ReservationNumber { get; set; }
        public string? Description { get; set; }
        public int RenterId { get; set; }

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

    }
}
