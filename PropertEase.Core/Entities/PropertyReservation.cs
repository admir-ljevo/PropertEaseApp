using PropertEase.Core.Entities.Base;
using PropertEase.Core.Entities.Identity;
using PropertEase.Core.Enumerations;

namespace PropertEase.Core.Entities
{
    public class PropertyReservation : BaseEntity
    {
        public Property Property { get; set; }
        public string ReservationNumber { get; set; }

        public int PropertyId { get; set; }
        public ApplicationUser Renter { get; set; }
        public int RenterId { get; set; }
        public ApplicationUser Client { get; set; }
        public int ClientId { get; set; }
        public int NumberOfGuests { get; set; }
        public DateTime DateOfOccupancyStart { get; set; }
        public DateTime DateOfOccupancyEnd { get; set; }
        public int NumberOfDays { get; set; }
        public int NumberOfMonths { get; set; }
        public double TotalPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }
        public string? Description { get; set; }

        /// <summary>
        /// Full lifecycle: Pending → Confirmed → Completed / Cancelled.
        /// </summary>
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

        // ── Audit trail ──────────────────────────────────────────────────────────

        /// <summary>UserId of the actor who confirmed (transitioned to Confirmed).</summary>
        public int? ConfirmedById { get; set; }

        /// <summary>Timestamp when the reservation was confirmed.</summary>
        public DateTime? ConfirmedAt { get; set; }

        /// <summary>UserId of the actor who cancelled the reservation.</summary>
        public int? CancelledById { get; set; }

        /// <summary>Timestamp when the reservation was cancelled.</summary>
        public DateTime? CancelledAt { get; set; }

        /// <summary>Reason provided when the reservation was cancelled.</summary>
        public string? CancellationReason { get; set; }

        // ── Backwards-compat ─────────────────────────────────────────────────────

        /// <summary>
        /// Helper: a reservation is "active" when Confirmed or Completed (i.e. was/is paid).
        /// </summary>
        [System.ComponentModel.DataAnnotations.Schema.NotMapped]
        public bool IsActive
        {
            get => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;
            set => Status = value ? ReservationStatus.Confirmed : ReservationStatus.Cancelled;
        }
    }
}
