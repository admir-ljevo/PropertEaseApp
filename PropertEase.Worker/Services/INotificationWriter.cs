namespace PropertEase.Worker.Services;

public interface INotificationWriter
{
    Task WriteAsync(int userId, int? reservationId, string message,
        string? reservationNumber, string? propertyName, string? propertyPhotoUrl);
}
