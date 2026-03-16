using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace PropertEase.Worker.Services;

public class SqlNotificationWriter : INotificationWriter
{
    private readonly string _connectionString;

    public SqlNotificationWriter(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("DefaultConnection string is missing.");
    }

    public async Task WriteAsync(int userId, int? reservationId, string message,
        string? reservationNumber, string? propertyName, string? propertyPhotoUrl)
    {
        const string sql = @"
            INSERT INTO ReservationNotifications
                (UserId, ReservationId, Message, IsSeen, ReservationNumber, PropertyName, PropertyPhotoUrl, CreatedAt, IsDeleted)
            VALUES
                (@UserId, @ReservationId, @Message, 0, @ReservationNumber, @PropertyName, @PropertyPhotoUrl, GETDATE(), 0)";

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync();
        await using var cmd = new SqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@UserId", userId);
        cmd.Parameters.AddWithValue("@ReservationId", (object?)reservationId ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Message", message);
        cmd.Parameters.AddWithValue("@ReservationNumber", (object?)reservationNumber ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@PropertyName", (object?)propertyName ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@PropertyPhotoUrl", (object?)propertyPhotoUrl ?? DBNull.Value);
        await cmd.ExecuteNonQueryAsync();
    }
}
