using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Dto.PropertyReservation
{
    public class PropertyReservationDto : BaseDto
    {
        public PropertyDto Property { get; set; }
        public int PropertyId { get; set; }
        public string? ReservationNumber { get; set; }
        public string? Description { get; set; }
        public ApplicationUserDto Renter { get; set; }
        public int RenterId { get; set; }
        public ApplicationUserDto Client { get; set; }
        public int ClientId { get; set; }
        public int NumberOfGuests { get; set; }
        public DateTime DateOfOccupancyStart { get; set; }
        public DateTime DateOfOccupancyEnd { get; set; }
        public int NumberOfDays { get; set; }
        public int NumberOfMonths { get; set; }
        public double TotalPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }

        /// <summary>Full lifecycle status: Pending → Confirmed → Completed / Cancelled.</summary>
        public ReservationStatus Status { get; set; }

        /// <summary>Backwards-compatible helper derived from Status.</summary>
        public bool IsActive => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;

        /// <summary>True once a completed payment record exists for this reservation.</summary>
        public bool IsPaid { get; set; }

        /// <summary>Populated in report projections. True when the payment was refunded.</summary>
        public bool IsRefunded { get; set; }

        // ── Audit trail ──────────────────────────────────────────────────────────
        public int? ConfirmedById { get; set; }
        public DateTime? ConfirmedAt { get; set; }
        public int? CancelledById { get; set; }
        public DateTime? CancelledAt { get; set; }
        public string? CancellationReason { get; set; }
        public string? CancelledByName { get; set; }
        public string? ConfirmedByName { get; set; }
    }
}
