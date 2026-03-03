using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MobiFon.Core.Entities;
using MobiFon.Core.Entities.Identity;

namespace MobiFon.Infrastructure.Seed;

/// <summary>
/// Seeds required reference data and test users on first run.
/// Call DatabaseSeeder.SeedAsync(serviceProvider) from Program.cs after app.Build().
/// </summary>
public static class DatabaseSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<DatabaseContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<DatabaseContext>>();

        try
        {
            await db.Database.MigrateAsync();

            await SeedRolesAsync(roleManager);
            await SeedReferenceDataAsync(db);
            await SeedUsersAsync(userManager, db, logger);

            logger.LogInformation("Database seeding completed.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred during database seeding.");
            throw;
        }
    }

    // ─── ROLES ────────────────────────────────────────────────────────────────

    private static async Task SeedRolesAsync(RoleManager<ApplicationRole> roleManager)
    {
        string[] roles = { "Admin", "Izdavac", "Korisnik" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
                await roleManager.CreateAsync(new ApplicationRole { Name = role });
        }
    }

    // ─── REFERENCE DATA ────────────────────────────────────────────────────────

    private static async Task SeedReferenceDataAsync(DatabaseContext db)
    {
        // Countries
        if (!await db.Countries.AnyAsync())
        {
            db.Countries.AddRange(
                new Country { Name = "Bosna i Hercegovina" },
                new Country { Name = "Hrvatska" },
                new Country { Name = "Srbija" }
            );
            await db.SaveChangesAsync();
        }

        // Cities (need countryId=1 which is BiH)
        if (!await db.Cities.AnyAsync())
        {
            var bih = await db.Countries.FirstAsync(c => c.Name == "Bosna i Hercegovina");
            db.Cities.AddRange(
                new City { Name = "Sarajevo", CountryId = bih.Id },
                new City { Name = "Mostar", CountryId = bih.Id },
                new City { Name = "Banja Luka", CountryId = bih.Id },
                new City { Name = "Tuzla", CountryId = bih.Id },
                new City { Name = "Zenica", CountryId = bih.Id }
            );
            await db.SaveChangesAsync();
        }

        // Property types
        if (!await db.PropertyTypes.AnyAsync())
        {
            db.PropertyTypes.AddRange(
                new PropertyType { Name = "Stan" },
                new PropertyType { Name = "Kuća" },
                new PropertyType { Name = "Villa" },
                new PropertyType { Name = "Studio" },
                new PropertyType { Name = "Poslovni prostor" }
            );
            await db.SaveChangesAsync();
        }
    }

    // ─── USERS ─────────────────────────────────────────────────────────────────

    private static async Task SeedUsersAsync(
        UserManager<ApplicationUser> userManager,
        DatabaseContext db,
        ILogger logger)
    {
        async Task CreateUser(string username, string password, string role, bool isAdmin = false, bool isEmployee = false, bool isClient = false)
        {
            var city = await db.Cities.FirstOrDefaultAsync();

            var existingUser = await userManager.FindByNameAsync(username);
            if (existingUser != null)
            {
                // User exists — repair missing Person and role assignment
                if (!await db.Persons.AnyAsync(p => p.ApplicationUserId == existingUser.Id))
                {
                    db.Persons.Add(new Person
                    {
                        FirstName = username,
                        LastName = "Test",
                        BirthDate = new DateTime(1990, 1, 1),
                        BirthPlaceId = city?.Id,
                        ApplicationUserId = existingUser.Id,
                        Address = "N/A",
                        PostCode = "00000"
                    });
                    await db.SaveChangesAsync();
                    logger.LogInformation("Repaired missing Person for existing user: {Username}", username);
                }
                if (!await userManager.IsInRoleAsync(existingUser, role))
                    await userManager.AddToRoleAsync(existingUser, role);
                return;
            }

            var user = new ApplicationUser
            {
                UserName = username,
                Email = $"{username}@propertease.test",
                EmailConfirmed = true,
                IsAdministrator = isAdmin,
                IsEmployee = isEmployee,
                IsClient = isClient,
                Active = true
            };

            var result = await userManager.CreateAsync(user, password);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, role);

                db.Persons.Add(new Person
                {
                    FirstName = username,
                    LastName = "Test",
                    BirthDate = new DateTime(1990, 1, 1),
                    BirthPlaceId = city?.Id,
                    ApplicationUserId = user.Id,
                    Address = "N/A",
                    PostCode = "00000"
                });
                await db.SaveChangesAsync();

                logger.LogInformation("Seeded user: {Username} with role {Role}", username, role);
            }
            else
            {
                logger.LogWarning("Failed to seed user {Username}: {Errors}",
                    username, string.Join(", ", result.Errors.Select(e => e.Description)));
            }
        }

        // Desktop admin user
        await CreateUser("desktop", "Test123!", "Admin", isAdmin: true);
        // Mobile client user
        await CreateUser("mobile", "Test123!", "Korisnik", isClient: true);
        // Izdavač (landlord) user
        await CreateUser("izdavac", "Test123!", "Izdavac", isEmployee: true);
    }
}
