using Microsoft.Extensions.Caching.Memory;

namespace PropertEase.Shared.Services.TokenBlacklist;

public class TokenBlacklistService : ITokenBlacklistService
{
    private readonly IMemoryCache _cache;
    private const string Prefix = "jwt_blacklist:";

    public TokenBlacklistService(IMemoryCache cache)
    {
        _cache = cache;
    }

    public void Revoke(string token, DateTimeOffset expiry)
    {
        var ttl = expiry - DateTimeOffset.UtcNow;
        if (ttl > TimeSpan.Zero)
            _cache.Set(Prefix + token, true, ttl);
    }

    public bool IsRevoked(string token) =>
        _cache.TryGetValue(Prefix + token, out _);
}
