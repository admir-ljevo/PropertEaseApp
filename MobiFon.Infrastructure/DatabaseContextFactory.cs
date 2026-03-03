using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace MobiFon.Infrastructure;

/// <summary>
/// Used by EF Core design-time tools (migrations) only.
/// Update the connection string below to match your local SQL Server instance.
/// </summary>
public class DatabaseContextFactory : IDesignTimeDbContextFactory<DatabaseContext>
{
    public DatabaseContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<DatabaseContext>();
        optionsBuilder.UseSqlServer(
            "Server=DESKTOP-LPAEI97\\MSSQLSERVER_OLAP;Database=PropertEaseDb;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=True");
        return new DatabaseContext(optionsBuilder.Options);
    }
}
