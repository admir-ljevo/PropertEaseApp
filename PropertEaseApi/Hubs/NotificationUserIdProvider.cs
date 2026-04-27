using Microsoft.AspNetCore.SignalR;

namespace PropertEase.Api.Hubs;

public class NotificationUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
        => connection.User?.FindFirst("Id")?.Value;
}
