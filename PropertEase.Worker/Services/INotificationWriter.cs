namespace PropertEase.Worker.Services;

public interface INotificationWriter
{
    Task<int> WriteAsync(int userId, int? reservationId, string? title, string message,
        string? reservationNumber, string? propertyName, string? propertyPhotoUrl);
}
