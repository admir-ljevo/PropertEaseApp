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

        // Pending Confirmed Completed / Cancelled.
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

        // Audit trail 

        public int? ConfirmedById { get; set; }
        public DateTime? ConfirmedAt { get; set; }
        public int? CancelledById { get; set; }
        public DateTime? CancelledAt { get; set; }
        public string? CancellationReason { get; set; }


        [System.ComponentModel.DataAnnotations.Schema.NotMapped]
        public bool IsActive
        {
            get => Status == ReservationStatus.Confirmed || Status == ReservationStatus.Completed;
            set => Status = value ? ReservationStatus.Confirmed : ReservationStatus.Cancelled;
        }
    }
}
