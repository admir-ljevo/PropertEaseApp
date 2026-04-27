namespace PropertEase.Core.Dto.Payment
{
    public class CompleteReservationPaymentDto
    {
        public string PayPalPaymentId { get; set; }
        public string PayPalPayerId { get; set; }
        public double Amount { get; set; }

        public int PropertyId { get; set; }
        public int ClientId { get; set; }
        public int RenterId { get; set; }
        public int NumberOfGuests { get; set; }
        public DateTime DateOfOccupancyStart { get; set; }
        public DateTime DateOfOccupancyEnd { get; set; }
        public int NumberOfDays { get; set; }
        public int NumberOfMonths { get; set; }
        public double TotalPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }
        public string? Description { get; set; }
    }
}
