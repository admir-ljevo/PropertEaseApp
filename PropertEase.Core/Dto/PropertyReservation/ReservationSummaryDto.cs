using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Dto.PropertyReservation
{
    public class ReservationSummaryDto
    {
        public int Id { get; set; }
        public string? ReservationNumber { get; set; }
        public DateTime? DateOfOccupancyStart { get; set; }
        public DateTime? DateOfOccupancyEnd { get; set; }
        public double? TotalPrice { get; set; }
        public ReservationStatus Status { get; set; }
        public bool IsActive => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;
        public bool IsPaid => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;
        public string? PropertyName { get; set; }
        public string? CancellationReason { get; set; }
    }
}
