namespace PropertEase.Shared.Services.TokenBlacklist;

public interface ITokenBlacklistService
{
    void Revoke(string token, DateTimeOffset expiry);
    bool IsRevoked(string token);
}
