namespace PropertEase.Worker.Services;

public interface IEmailService
{
    Task SendReservationConfirmationAsync(string to, string clientName, string propertyName,
        string reservationNumber, DateTime checkIn, DateTime checkOut, decimal totalPrice);

    Task SendReservationCancellationAsync(string to, string clientName, string propertyName,
        string reservationNumber, string reason);

    Task SendGenericEmailAsync(string to, string subject, string htmlBody);
}
