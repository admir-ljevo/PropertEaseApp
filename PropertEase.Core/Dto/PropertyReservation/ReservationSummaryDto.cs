namespace PropertEase.Core.Dto.PropertyReservation
{
    public class ReservationSummaryDto
    {
        public int Id { get; set; }
        public string? ReservationNumber { get; set; }
        public DateTime? DateOfOccupancyStart { get; set; }
        public DateTime? DateOfOccupancyEnd { get; set; }
        public double? TotalPrice { get; set; }
        public bool? IsActive { get; set; }
        public string? PropertyName { get; set; }
    }
}
