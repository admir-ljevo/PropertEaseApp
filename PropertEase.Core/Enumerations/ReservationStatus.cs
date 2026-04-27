namespace PropertEase.Core.Enumerations
{
    public enum ReservationStatus
    {
        Pending = 0,
        Confirmed = 1,   // payment verified, reservation is active
        Completed = 2,
        Cancelled = 3
    }
}
