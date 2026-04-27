using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Dto.PropertyReservation
{
    public class PropertyReservationUpsertDto : BaseDto
    {
        public int PropertyId { get; set; }
        public string? ReservationNumber { get; set; }
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

        /// <summary>Desired target status. State machine validates the transition on the server.</summary>
        public ReservationStatus Status { get; set; } = ReservationStatus.Confirmed;

        /// <summary>Required when Status = Cancelled. Stored in the audit trail.</summary>
        public string? CancellationReason { get; set; }

        /// <summary>Backwards-compatible setter; maps to Status.</summary>
        public bool IsActive
        {
            get => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;
            set => Status = value ? ReservationStatus.Confirmed : ReservationStatus.Cancelled;
        }
    }
}
