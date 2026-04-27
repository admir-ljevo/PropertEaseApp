using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Entities;
using PropertEase.Core.Entities.Identity;
using PropertEase.Core.Enumerations;

namespace PropertEase.Infrastructure.Seed;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db          = scope.ServiceProvider.GetRequiredService<DatabaseContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
        var hasher      = scope.ServiceProvider.GetRequiredService<IPasswordHasher<ApplicationUser>>();
        var logger      = scope.ServiceProvider.GetRequiredService<ILogger<DatabaseContext>>();
        var env         = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>();

        try
        {
            await db.Database.MigrateAsync();
            await SeedRolesAsync(roleManager);
            await SeedReferenceDataAsync(db);
            await SeedUsersAsync(userManager, hasher, db, logger);
            await SeedPropertiesAsync(db, userManager, logger, env.WebRootPath);
            await SeedReservationsAsync(db, userManager, logger);
            await SeedPaymentsAsync(db, userManager, logger);
            await SeedReservationNotificationsAsync(db, userManager, logger);
            await SeedRatingsAsync(db, userManager, logger);
            await SeedProfilePhotosAsync(db, userManager, logger, env.WebRootPath);
            await SeedConversationsAsync(db, userManager, logger);
            await SeedNotificationsAsync(db, userManager, logger, env.WebRootPath);
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
        var roles = new (string Name, int Level)[]
        {
            ("Admin",  0),
            ("Renter", 1),
            ("Client", 2),
        };
        foreach (var (name, level) in roles)
        {
            if (!await roleManager.RoleExistsAsync(name))
                await roleManager.CreateAsync(new ApplicationRole { Name = name, RoleLevel = level });
        }
    }

    // ─── REFERENCE DATA ───────────────────────────────────────────────────────

    private static async Task SeedReferenceDataAsync(DatabaseContext db)
    {
        if (!await db.Countries.AnyAsync())
        {
            db.Countries.AddRange(
                new Country { Name = "Bosna i Hercegovina" },
                new Country { Name = "Hrvatska" },
                new Country { Name = "Srbija" }
            );
            await db.SaveChangesAsync();
        }

        if (!await db.Cities.AnyAsync())
        {
            var bih = await db.Countries.FirstAsync(c => c.Name == "Bosna i Hercegovina");
            db.Cities.AddRange(
                new City { Name = "Sarajevo",   CountryId = bih.Id },
                new City { Name = "Mostar",     CountryId = bih.Id },
                new City { Name = "Banja Luka", CountryId = bih.Id },
                new City { Name = "Tuzla",      CountryId = bih.Id },
                new City { Name = "Zenica",     CountryId = bih.Id }
            );
            await db.SaveChangesAsync();
        }

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

    // ─── USERS ────────────────────────────────────────────────────────────────

    private static async Task SeedUsersAsync(
        UserManager<ApplicationUser> userManager,
        IPasswordHasher<ApplicationUser> hasher,
        DatabaseContext db,
        ILogger logger)
    {
        var city = await db.Cities.FirstOrDefaultAsync();

        await EnsureUser(userManager, hasher, db, logger, new ApplicationUser
        {
            UserName       = "desktop",
            Email          = "desktop@propertease.test",
            EmailConfirmed = true,
            Active         = true,
            PhoneNumber    = "+38761100001",
        }, password: "test", roles: new[] { "Admin", "Renter" }, firstName: "Admin", lastName: "Korisnik", city: city,
           jmbg: "0101990171001");

        await EnsureUser(userManager, hasher, db, logger, new ApplicationUser
        {
            UserName       = "mobile",
            Email          = "mobile@propertease.test",
            EmailConfirmed = true,
            Active         = true,
            PhoneNumber    = "+38761100002",
        }, password: "test", roles: new[] { "Client" }, firstName: "Mobilni", lastName: "Korisnik", city: city,
           jmbg: "1501991171002");

        await EnsureUser(userManager, hasher, db, logger, new ApplicationUser
        {
            UserName       = "izdavac",
            Email          = "izdavac@propertease.test",
            EmailConfirmed = true,
            Active         = true,
            PhoneNumber    = "+38762100003",
        }, password: "test", roles: new[] { "Renter" }, firstName: "Marko", lastName: "Izdavač", city: city,
           jmbg: "2003990171003");
    }

    private static async Task EnsureUser(
        UserManager<ApplicationUser> userManager,
        IPasswordHasher<ApplicationUser> hasher,
        DatabaseContext db,
        ILogger logger,
        ApplicationUser user,
        string password,
        string[] roles,
        string firstName,
        string lastName,
        City? city,
        string? jmbg = null)
    {
        var existing = await userManager.FindByNameAsync(user.UserName!);
        if (existing != null)
        {
            existing.PasswordHash = hasher.HashPassword(existing, password);
            existing.Active       = true;
            existing.PhoneNumber  = user.PhoneNumber;
            await userManager.UpdateAsync(existing);

            foreach (var role in roles)
                if (!await userManager.IsInRoleAsync(existing, role))
                    await userManager.AddToRoleAsync(existing, role);

            if (!await db.Persons.AnyAsync(p => p.ApplicationUserId == existing.Id))
            {
                db.Persons.Add(MakePerson(firstName, lastName, existing.Id, city, jmbg));
                await db.SaveChangesAsync();
            }
            else
            {
                var person = await db.Persons.FirstAsync(p => p.ApplicationUserId == existing.Id);
                if (person.JMBG == null && jmbg != null) { person.JMBG = jmbg; await db.SaveChangesAsync(); }
            }
            return;
        }

        var result = await userManager.CreateAsync(user);
        if (!result.Succeeded)
        {
            logger.LogWarning("Failed to create {User}: {Errors}", user.UserName,
                string.Join(", ", result.Errors.Select(e => e.Description)));
            return;
        }

        user.PasswordHash = hasher.HashPassword(user, password);
        await userManager.UpdateAsync(user);

        foreach (var role in roles)
            await userManager.AddToRoleAsync(user, role);

        db.Persons.Add(MakePerson(firstName, lastName, user.Id, city, jmbg));
        await db.SaveChangesAsync();

        logger.LogInformation("Seeded user '{Username}' with roles '{Roles}'.", user.UserName, string.Join(", ", roles));
    }

    private static Person MakePerson(string firstName, string lastName, int userId, City? city, string? jmbg = null) =>
        new Person
        {
            FirstName         = firstName,
            LastName          = lastName,
            BirthDate         = new DateTime(1990, 1, 1),
            BirthPlaceId      = city?.Id,
            ApplicationUserId = userId,
            Address           = "Testna ulica 1",
            PostCode          = "71000",
            JMBG              = jmbg,
            CreatedAt         = DateTime.UtcNow,
        };

    // ─── PROPERTIES ───────────────────────────────────────────────────────────

    private static async Task SeedPropertiesAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger,
        string webRootPath)
    {
        if (await db.Properties.AnyAsync()) return;

        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (admin == null || renter == null) return;

        var sarajevo  = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Sarajevo");
        var mostar    = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Mostar");
        var banjaLuka = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Banja Luka");
        var tuzla     = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Tuzla");
        var zenica    = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Zenica");

        var stan   = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Stan");
        var kuca   = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Kuća");
        var villa  = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Villa");
        var studio = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Studio");

        var propertyDefs = new[]
        {
            // ── 5 belong to desktop (admin) ──────────────────────────────────
            new PropertyDef("Luksuzni stan Sarajevo centar", admin.Id,  stan!.Id,   sarajevo!.Id,
                "Centralna lokacija, pogled na Baščaršiju.",
                3, 2, 90,  5, 1200f, 0f,    true,  true,  true,  true,  false, true,  43.8563, 18.4131),
            new PropertyDef("Studio Bašćaršija",             admin.Id,  studio!.Id, sarajevo.Id,
                "Studio apartman idealan za jednu osobu, blizu centra.",
                1, 1, 35,  2, 0f,    45f,   false, true,  true,  false, false, false, 43.8601, 18.4321),
            new PropertyDef("Apartman Banja Luka Centar",    admin.Id,  stan.Id,    banjaLuka!.Id,
                "Moderan stan u centru Banje Luke, potpuno opremljen.",
                2, 1, 65,  4, 750f,  0f,    true,  true,  true,  true,  false, true,  44.7722, 17.1910),
            new PropertyDef("Kuća sa vrtom Tuzla",           admin.Id,  kuca!.Id,   tuzla!.Id,
                "Prostrana porodična kuća sa velikim vrtom i garažom.",
                5, 2, 180, 8, 0f,    70f,   false, true,  false, false, false, false, 44.5384, 18.6734),
            new PropertyDef("Penthouse Zenica",              admin.Id,  stan.Id,    zenica!.Id,
                "Ekskluzivni penthouse sa panoramskim pogledom.",
                4, 3, 150, 6, 1500f, 0f,    true,  true,  true,  true,  false, true,  44.2031, 17.9078),

            // ── 5 belong to izdavac (renter) ─────────────────────────────────
            new PropertyDef("Vila Blagaj",                    renter.Id, villa!.Id,  mostar!.Id,
                "Autentična vila u srcu Blagaja, uz izvor Bune.",
                4, 2, 140, 8, 0f,    90f,   false, true,  true,  true,  true,  true,  43.2625, 17.9057),
            new PropertyDef("Apartman Mostar Stari Grad",     renter.Id, stan.Id,    mostar.Id,
                "Tradicionalni apartman uz Stari most, pogled na Neretvu.",
                2, 1, 70,  4, 850f,  0f,    true,  true,  true,  true,  false, false, 43.3372, 17.8138),
            new PropertyDef("Kuća Radobolja",                 renter.Id, kuca.Id,    mostar.Id,
                "Mirna seoska kuća uz rijeku Radobolju, idealna za odmor.",
                3, 2, 120, 6, 0f,    55f,   false, false, false, false, false, false, 43.3100, 17.8200),
            new PropertyDef("Studio Neretva",                 renter.Id, studio.Id,  mostar.Id,
                "Kompaktan studio s pogledom na rijeku Neretvu.",
                1, 1, 40,  2, 0f,    40f,   false, true,  true,  false, false, true,  43.3464, 17.8077),
            new PropertyDef("Luksuzna villa Sarajevo Ilidža", renter.Id, villa.Id,   sarajevo.Id,
                "Moderna luksuzna villa na Ilidži s bazenom i teniskim terenom.",
                6, 4, 280, 10, 0f,   180f,  false, true,  true,  true,  true,  true,  43.8270, 18.3100),
        };

        int[] picsumSeeds = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };

        var uploadsDir = Path.Combine(webRootPath, "uploads", "images");
        Directory.CreateDirectory(uploadsDir);

        for (int i = 0; i < propertyDefs.Length; i++)
        {
            var def = propertyDefs[i];
            var property = new Property
            {
                Name              = def.Name,
                ApplicationUserId = def.OwnerId,
                PropertyTypeId    = def.TypeId,
                CityId            = def.CityId,
                Description       = def.Description,
                NumberOfRooms     = def.Rooms,
                NumberOfBathrooms = def.Baths,
                SquareMeters      = def.Sqm,
                Capacity          = def.Cap,
                MonthlyPrice      = def.IsMonthlyRental ? def.Monthly : null,
                DailyPrice        = def.IsMonthlyRental ? null : def.Daily,
                IsMonthly         = def.IsMonthlyRental,
                IsDaily           = !def.IsMonthlyRental,
                HasWiFi           = def.WiFi,
                IsFurnished       = def.Furnished,
                HasBalcony        = def.Balcony,
                HasPool           = def.Pool,
                HasAirCondition   = def.AC,
                HasTV             = true,
                IsAvailable       = true,
                Latitude          = def.Lat,
                Longitude         = def.Lng,
                Address           = $"Testna adresa {i + 1}",
                AverageRating     = 0,
                CreatedAt         = DateTime.UtcNow,
            };
            db.Properties.Add(property);
            await db.SaveChangesAsync();

            for (int j = 0; j < 3; j++)
            {
                int seed     = picsumSeeds[i] + j;
                var imageUrl = $"https://picsum.photos/seed/{seed}/800/600";
                var bytes    = await DownloadImageAsync(imageUrl, logger);
                var fileName = $"property{property.Id}_img{j + 1}_{Guid.NewGuid():N}.jpg";
                var filePath = Path.Combine(uploadsDir, fileName);
                var urlPath  = $"/uploads/images/{fileName}";

                if (bytes != null)
                    await File.WriteAllBytesAsync(filePath, bytes);

                db.Photos.Add(new Photo
                {
                    PropertyId = property.Id,
                    Url        = urlPath,
                    ImageBytes = bytes,
                    CreatedAt  = DateTime.UtcNow,
                });
            }
            await db.SaveChangesAsync();
            logger.LogInformation("Seeded property '{Name}' with 3 images.", property.Name);
        }
    }

    // ─── RESERVATIONS ─────────────────────────────────────────────────────────

    private static async Task SeedReservationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.PropertyReservations.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var props = await db.Properties.Where(p => !p.IsDeleted).OrderBy(p => p.Id).ToListAsync();
        if (props.Count < 10) return;

        var now = DateTime.UtcNow;

        // ── 1. Confirmed – future check-in (daily, admin prop) ────────────────
        var r1Start = new DateTime(2026, 5, 1);
        var r1End   = new DateTime(2026, 5, 8);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0001",
            PropertyId           = props[1].Id,   // Studio Bašćaršija – daily 45/day
            RenterId             = admin.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 2,
            DateOfOccupancyStart = r1Start,
            DateOfOccupancyEnd   = r1End,
            NumberOfDays         = 7,
            NumberOfMonths       = 1,
            TotalPrice           = 315,            // 45 * 7
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Confirmed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = now.AddDays(-10),
            Description          = "Dolazim sa partnerom, molim za tiho smještanje.",
            CreatedAt            = now.AddDays(-10),
        });

        // ── 2. Confirmed – currently ongoing (daily, renter prop) ─────────────
        var r2Start = new DateTime(2026, 4, 10);
        var r2End   = new DateTime(2026, 4, 30);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0002",
            PropertyId           = props[5].Id,   // Vila Blagaj – daily 90/day
            RenterId             = renter.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 4,
            DateOfOccupancyStart = r2Start,
            DateOfOccupancyEnd   = r2End,
            NumberOfDays         = 20,
            NumberOfMonths       = 1,
            TotalPrice           = 1800,           // 90 * 20
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Confirmed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = now.AddDays(-15),
            Description          = "Porodični odmor, potrebne su dvije sobe.",
            CreatedAt            = now.AddDays(-15),
        });

        // ── 3. Completed – past monthly rental (renter prop) ──────────────────
        var r3Start = new DateTime(2026, 1, 1);
        var r3End   = new DateTime(2026, 2, 1);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0003",
            PropertyId           = props[6].Id,   // Apartman Mostar Stari Grad – monthly 850/month
            RenterId             = renter.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 2,
            DateOfOccupancyStart = r3Start,
            DateOfOccupancyEnd   = r3End,
            NumberOfDays         = 31,
            NumberOfMonths       = 1,
            TotalPrice           = 850,
            IsDaily              = false,
            IsMonthly            = true,
            Status               = ReservationStatus.Completed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = new DateTime(2025, 12, 20),
            Description          = "Duži boravak radi posla.",
            CreatedAt            = new DateTime(2025, 12, 20),
        });

        // ── 4. Completed – past daily rental (admin prop) ─────────────────────
        var r4Start = new DateTime(2026, 2, 10);
        var r4End   = new DateTime(2026, 2, 15);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0004",
            PropertyId           = props[3].Id,   // Kuća sa vrtom Tuzla – daily 70/day
            RenterId             = admin.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 3,
            DateOfOccupancyStart = r4Start,
            DateOfOccupancyEnd   = r4End,
            NumberOfDays         = 5,
            NumberOfMonths       = 1,
            TotalPrice           = 350,            // 70 * 5
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Completed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = new DateTime(2026, 2, 1),
            Description          = "Kratki vikend odmor.",
            CreatedAt            = new DateTime(2026, 2, 1),
        });

        // ── 5. Cancelled by client – had paid (admin prop) ────────────────────
        var r5Start = new DateTime(2026, 4, 1);
        var r5End   = new DateTime(2026, 5, 1);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0005",
            PropertyId           = props[2].Id,   // Apartman Banja Luka – monthly 750/month
            RenterId             = admin.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 2,
            DateOfOccupancyStart = r5Start,
            DateOfOccupancyEnd   = r5End,
            NumberOfDays         = 30,
            NumberOfMonths       = 1,
            TotalPrice           = 750,
            IsDaily              = false,
            IsMonthly            = true,
            Status               = ReservationStatus.Cancelled,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = new DateTime(2026, 3, 10),
            CancelledById        = mobile.Id,
            CancelledAt          = new DateTime(2026, 3, 20),
            CancellationReason   = "Klijent otkazao zbog promjene poslovnih planova.",
            Description          = "Planirani poslovni boravak.",
            CreatedAt            = new DateTime(2026, 3, 10),
        });

        // ── 6. Cancelled by renter – had paid (renter prop) ───────────────────
        var r6Start = new DateTime(2026, 3, 15);
        var r6End   = new DateTime(2026, 3, 20);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0006",
            PropertyId           = props[7].Id,   // Kuća Radobolja – daily 55/day
            RenterId             = renter.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 5,
            DateOfOccupancyStart = r6Start,
            DateOfOccupancyEnd   = r6End,
            NumberOfDays         = 5,
            NumberOfMonths       = 1,
            TotalPrice           = 275,            // 55 * 5
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Cancelled,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = new DateTime(2026, 3, 5),
            CancelledById        = renter.Id,
            CancelledAt          = new DateTime(2026, 3, 10),
            CancellationReason   = "Nekretnina privremeno nedostupna zbog hitnog renoviranja.",
            Description          = "Grupni odmor.",
            CreatedAt            = new DateTime(2026, 3, 5),
        });

        // ── 7. Pending – awaiting payment (admin prop) ────────────────────────
        var r7Start = new DateTime(2026, 6, 1);
        var r7End   = new DateTime(2026, 6, 8);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0007",
            PropertyId           = props[0].Id,   // Luksuzni stan Sarajevo – monthly 1200/month
            RenterId             = admin.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 2,
            DateOfOccupancyStart = r7Start,
            DateOfOccupancyEnd   = r7End,
            NumberOfDays         = 7,
            NumberOfMonths       = 1,
            TotalPrice           = 1200,
            IsDaily              = false,
            IsMonthly            = true,
            Status               = ReservationStatus.Pending,
            Description          = "Čeka na uplatu.",
            CreatedAt            = now.AddDays(-2),
        });

        // ── 8. Pending – awaiting payment (renter prop) ───────────────────────
        var r8Start = new DateTime(2026, 7, 1);
        var r8End   = new DateTime(2026, 7, 4);
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0008",
            PropertyId           = props[9].Id,   // Luksuzna villa Sarajevo Ilidža – daily 180/day
            RenterId             = renter.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 6,
            DateOfOccupancyStart = r8Start,
            DateOfOccupancyEnd   = r8End,
            NumberOfDays         = 3,
            NumberOfMonths       = 1,
            TotalPrice           = 540,            // 180 * 3
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Pending,
            Description          = "Ljetovanje sa porodicom.",
            CreatedAt            = now.AddDays(-1),
        });

        var yesterday = now.Date.AddDays(-1);

        // ── 9. Confirmed – started yesterday, ongoing (admin prop) ───────────
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0009",
            PropertyId           = props[4].Id,   // Penthouse Zenica – monthly 1500/month
            RenterId             = admin.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 3,
            DateOfOccupancyStart = yesterday,
            DateOfOccupancyEnd   = yesterday.AddDays(14),
            NumberOfDays         = 14,
            NumberOfMonths       = 1,
            TotalPrice           = 700,
            IsDaily              = false,
            IsMonthly            = true,
            Status               = ReservationStatus.Confirmed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = now.AddDays(-3),
            Description          = "Kratki poslovni boravak u Zenici.",
            CreatedAt            = now.AddDays(-3),
        });

        // ── 10. Confirmed – started yesterday, ongoing (renter prop) ─────────
        db.PropertyReservations.Add(new PropertyReservation
        {
            ReservationNumber    = "#0010",
            PropertyId           = props[8].Id,   // Studio Neretva – daily 40/day
            RenterId             = renter.Id,
            ClientId             = mobile.Id,
            NumberOfGuests       = 1,
            DateOfOccupancyStart = yesterday,
            DateOfOccupancyEnd   = yesterday.AddDays(30),
            NumberOfDays         = 30,
            NumberOfMonths       = 1,
            TotalPrice           = 1200,            // 40 * 30
            IsDaily              = true,
            IsMonthly            = false,
            Status               = ReservationStatus.Confirmed,
            ConfirmedById        = mobile.Id,
            ConfirmedAt          = now.AddDays(-5),
            Description          = "Duži odmor uz rijeku Neretvu.",
            CreatedAt            = now.AddDays(-5),
        });

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded 10 reservations (Confirmed×4, Completed×2, Cancelled×2, Pending×2).");
    }

    // ─── PAYMENTS ─────────────────────────────────────────────────────────────

    private static async Task SeedPaymentsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.Payments.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        if (mobile == null) return;

        var reservations = await db.PropertyReservations
            .OrderBy(r => r.Id)
            .ToListAsync();

        if (reservations.Count < 8) return;

        var r1 = reservations[0];
        var r2 = reservations[1];
        var r3 = reservations[2];
        var r4 = reservations[3];
        var r5 = reservations[4];
        var r6 = reservations[5];
        var r7  = reservations[6];
        var r9  = reservations.Count > 7 ? reservations[7] : null;
        var r10 = reservations.Count > 8 ? reservations[8] : null;

        var payments = new List<Payment>
        {
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r1.Id,
                PayPalPaymentId = "PAYID-SEED-0001",
                PayPalPayerId   = "PAYERID-SEED-001",
                Amount          = r1.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r1.ReservationNumber}",
                CreatedAt       = r1.ConfirmedAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r2.Id,
                PayPalPaymentId = "PAYID-SEED-0002",
                PayPalPayerId   = "PAYERID-SEED-002",
                Amount          = r2.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r2.ReservationNumber}",
                CreatedAt       = r2.ConfirmedAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r3.Id,
                PayPalPaymentId = "PAYID-SEED-0003",
                PayPalPayerId   = "PAYERID-SEED-003",
                Amount          = r3.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r3.ReservationNumber}",
                CreatedAt       = r3.ConfirmedAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r4.Id,
                PayPalPaymentId = "PAYID-SEED-0004",
                PayPalPayerId   = "PAYERID-SEED-004",
                Amount          = r4.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r4.ReservationNumber}",
                CreatedAt       = r4.ConfirmedAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r5.Id,
                PayPalPaymentId = "PAYID-SEED-0005",
                PayPalPayerId   = "PAYERID-SEED-005",
                Amount          = r5.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Refunded,
                Description     = $"Refund za rezervaciju {r5.ReservationNumber} – klijent otkazao",
                CreatedAt       = r5.CancelledAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r6.Id,
                PayPalPaymentId = "PAYID-SEED-0006",
                PayPalPayerId   = "PAYERID-SEED-006",
                Amount          = r6.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Refunded,
                Description     = $"Refund za rezervaciju {r6.ReservationNumber} – iznajmljivač otkazao",
                CreatedAt       = r6.CancelledAt ?? DateTime.UtcNow,
            },
            new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r7.Id,
                PayPalPaymentId = "PAYID-SEED-0007",
                PayPalPayerId   = "PAYERID-SEED-007",
                Amount          = r7.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Pending,
                Description     = $"Čekanje na plaćanje za rezervaciju {r7.ReservationNumber}",
                CreatedAt       = r7.CreatedAt,
            },
        };

        if (r9 != null)
            payments.Add(new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r9.Id,
                PayPalPaymentId = "PAYID-SEED-0009",
                PayPalPayerId   = "PAYERID-SEED-009",
                Amount          = r9.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r9.ReservationNumber}",
                CreatedAt       = r9.ConfirmedAt ?? DateTime.UtcNow,
            });

        if (r10 != null)
            payments.Add(new Payment
            {
                ClientId        = mobile.Id,
                ReservationId   = r10.Id,
                PayPalPaymentId = "PAYID-SEED-0010",
                PayPalPayerId   = "PAYERID-SEED-010",
                Amount          = r10.TotalPrice,
                Currency        = "BAM",
                Status          = PaymentStatus.Completed,
                Description     = $"Plaćanje za rezervaciju {r10.ReservationNumber}",
                CreatedAt       = r10.ConfirmedAt ?? DateTime.UtcNow,
            });

        db.Payments.AddRange(payments);
        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} payments.", payments.Count);
    }

    // ─── RESERVATION NOTIFICATIONS ────────────────────────────────────────────

    private static async Task SeedReservationNotificationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.ReservationNotifications.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var reservations = await db.PropertyReservations
            .Include(r => r.Property)
            .OrderBy(r => r.Id)
            .ToListAsync();

        if (reservations.Count < 6) return;

        var notifications = new List<ReservationNotification>();

        foreach (var res in reservations)
        {
            var photoUrl = await db.Photos
                .Where(p => p.PropertyId == res.PropertyId && !p.IsDeleted)
                .Select(p => p.Url)
                .FirstOrDefaultAsync();

            var propName = res.Property?.Name ?? "Nekretnina";
            var renterUserId = res.RenterId;

            switch (res.Status)
            {
                case ReservationStatus.Confirmed:
                case ReservationStatus.Completed:
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = renterUserId,
                        ReservationId     = res.Id,
                        Title             = "Nova rezervacija",
                        Message           = $"Nova rezervacija #{res.ReservationNumber} za nekretninu \"{propName}\".",
                        IsSeen            = res.Status == ReservationStatus.Completed,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = res.ConfirmedAt ?? res.CreatedAt,
                    });
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = mobile.Id,
                        ReservationId     = res.Id,
                        Title             = "Rezervacija potvrđena",
                        Message           = $"Vaša rezervacija {res.ReservationNumber} za \"{propName}\" je uspješno potvrđena.",
                        IsSeen            = true,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = res.ConfirmedAt ?? res.CreatedAt,
                    });
                    if (res.Status == ReservationStatus.Completed)
                    {
                        notifications.Add(new ReservationNotification
                        {
                            UserId            = mobile.Id,
                            ReservationId     = res.Id,
                            Title             = "Rezervacija završena",
                            Message           = $"Vaša rezervacija za \"{propName}\" je završena. Ocijenite vaš boravak i iznajmljivača.",
                            IsSeen            = false,
                            ReservationNumber = res.ReservationNumber,
                            PropertyName      = propName,
                            PropertyPhotoUrl  = photoUrl,
                            CreatedAt         = res.DateOfOccupancyEnd,
                        });
                    }
                    break;

                case ReservationStatus.Cancelled:
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = mobile.Id,
                        ReservationId     = res.Id,
                        Title             = "Rezervacija otkazana",
                        Message           = $"Vaša rezervacija {res.ReservationNumber} je otkazana. Razlog: {res.CancellationReason}",
                        IsSeen            = false,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = res.CancelledAt ?? res.CreatedAt,
                    });
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = mobile.Id,
                        ReservationId     = res.Id,
                        Title             = "Povrat sredstava",
                        Message           = $"Povrat sredstava za rezervaciju {res.ReservationNumber} je uspješno obrađen.",
                        IsSeen            = false,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = (res.CancelledAt ?? res.CreatedAt).AddMinutes(5),
                    });
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = renterUserId,
                        ReservationId     = res.Id,
                        Title             = "Rezervacija otkazana",
                        Message           = $"Rezervacija {res.ReservationNumber} za \"{propName}\" je otkazana. Razlog: {res.CancellationReason}",
                        IsSeen            = true,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = res.CancelledAt ?? res.CreatedAt,
                    });
                    break;

                case ReservationStatus.Pending:
                    notifications.Add(new ReservationNotification
                    {
                        UserId            = mobile.Id,
                        ReservationId     = res.Id,
                        Title             = "Rezervacija u obradi",
                        Message           = $"Vaša rezervacija {res.ReservationNumber} za \"{propName}\" čeka na plaćanje.",
                        IsSeen            = false,
                        ReservationNumber = res.ReservationNumber,
                        PropertyName      = propName,
                        PropertyPhotoUrl  = photoUrl,
                        CreatedAt         = res.CreatedAt,
                    });
                    break;
            }
        }

        db.ReservationNotifications.AddRange(notifications);
        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} reservation notifications.", notifications.Count);
    }

    // ─── RATINGS ──────────────────────────────────────────────────────────────

    private static async Task SeedRatingsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.PropertyRatings.AnyAsync() || await db.UserRatings.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var props = await db.Properties.Where(p => !p.IsDeleted).OrderBy(p => p.Id).Take(8).ToListAsync();
        if (props.Count == 0) return;

        var propertyRatings = new[]
        {
            (prop: props.ElementAtOrDefault(0), rating: 4.5, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Odličan stan, čisto i uredno. Lokacija je savršena za posjet centru."),
            (prop: props.ElementAtOrDefault(1), rating: 5.0, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Fantastičan studio, sve je bilo na svom mjestu. Definitivno preporučujem!"),
            (prop: props.ElementAtOrDefault(2), rating: 3.5, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Solidan smještaj, ali namještaj je malo zastarjelo. Čisto i uredno."),
            (prop: props.ElementAtOrDefault(3), rating: 4.0, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Lijepa kuća s velikom baštom. Mirno i ugodno okruženje."),
            (prop: props.ElementAtOrDefault(5), rating: 5.0, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Vila Blagaj je nešto posebno. Pogled na rijeku i priroda su nestvarna."),
            (prop: props.ElementAtOrDefault(6), rating: 4.5, reviewer: mobile.Id,  name: "Mobilni Korisnik",  desc: "Tradiconalni ambijent uz Stari most – autentično iskustvo."),
            (prop: props.ElementAtOrDefault(0), rating: 4.0, reviewer: admin.Id,   name: "Admin Korisnik",    desc: "Nekretnina je u odličnom stanju, gostima se svidjelo."),
            (prop: props.ElementAtOrDefault(5), rating: 4.5, reviewer: admin.Id,   name: "Admin Korisnik",    desc: "Iznajmljivač je veoma kooperativan i odgovoran."),
        };

        foreach (var (prop, rating, reviewer, name, desc) in propertyRatings)
        {
            if (prop == null) continue;
            db.PropertyRatings.Add(new PropertyRating
            {
                PropertyId   = prop.Id,
                ReviewerId   = reviewer,
                ReviewerName = name,
                Rating       = rating,
                Description  = desc,
                CreatedAt    = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 60)),
            });
        }

        db.UserRatings.AddRange(
            new UserRating
            {
                RenterId     = renter.Id,
                ReviewerId   = mobile.Id,
                ReviewerName = "Mobilni Korisnik",
                Rating       = 4.5,
                Description  = "Veoma komunikativan i profesionalan. Brzo odgovara na poruke.",
                CreatedAt    = DateTime.UtcNow.AddDays(-30),
            },
            new UserRating
            {
                RenterId     = admin.Id,
                ReviewerId   = mobile.Id,
                ReviewerName = "Mobilni Korisnik",
                Rating       = 5.0,
                Description  = "Izvrsna usluga i brz odgovor na sve upite. Nekretnina u savršenom stanju.",
                CreatedAt    = DateTime.UtcNow.AddDays(-15),
            },
            new UserRating
            {
                RenterId     = renter.Id,
                ReviewerId   = admin.Id,
                ReviewerName = "Admin Korisnik",
                Rating       = 4.0,
                Description  = "Pouzdani iznajmljivač, nekretnine su uvijek dobro održavane.",
                CreatedAt    = DateTime.UtcNow.AddDays(-5),
            }
        );

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded property and user ratings.");
    }

    // ─── PROFILE PHOTOS ───────────────────────────────────────────────────────

    private static async Task SeedProfilePhotosAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger,
        string webRootPath)
    {
        var users        = new[] { "desktop", "mobile", "izdavac" };
        int[] picsumSeeds = { 200, 201, 202 };

        var uploadsDir = Path.Combine(webRootPath, "uploads", "images");
        Directory.CreateDirectory(uploadsDir);

        for (int i = 0; i < users.Length; i++)
        {
            var user = await userManager.FindByNameAsync(users[i]);
            if (user == null) continue;

            var person = await db.Persons.FirstOrDefaultAsync(p => p.ApplicationUserId == user.Id);
            if (person == null || person.ProfilePhoto != null) continue;

            var url      = $"https://picsum.photos/seed/{picsumSeeds[i]}/200/200";
            var bytes    = await DownloadImageAsync(url, logger);
            if (bytes == null) continue;

            var fileName = $"avatar_{users[i]}_{Guid.NewGuid():N}.jpg";
            var filePath = Path.Combine(uploadsDir, fileName);

            await File.WriteAllBytesAsync(filePath, bytes);

            person.ProfilePhoto          = $"/uploads/images/{fileName}";
            person.ProfilePhotoThumbnail = $"/uploads/images/{fileName}";
            person.ProfilePhotoBytes     = bytes;
        }

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded profile photos for users.");
    }

    // ─── CONVERSATIONS & MESSAGES ─────────────────────────────────────────────

    private static async Task SeedConversationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.Conversations.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var props = await db.Properties.Where(p => !p.IsDeleted).OrderBy(p => p.Id).ToListAsync();
        if (props.Count < 8) return;

        var now = DateTime.UtcNow;

        // ── Conversation 1: mobile ↔ renter about Vila Blagaj ─────────────────
        await AddConversation(db, mobile, renter, props[5], now.AddHours(-5), new[]
        {
            (mobile.Id, renter.Id, "Pozdrav! Da li je vila slobodna u periodu 10-30. aprila?",                                               now.AddHours(-5)),
            (renter.Id, mobile.Id, "Zdravo! Da, vila je slobodna. Cijena je 90 KM po noći.",                                                 now.AddHours(-4)),
            (mobile.Id, renter.Id, "Odlično! Da li su dostupne dvije zasebne spavaće sobe?",                                                  now.AddHours(-3)),
            (renter.Id, mobile.Id, "Da, vila ima 4 spavaće sobe, sve sa zasebnim kupatilima. Bazen je također dostupan.",                     now.AddHours(-2)),
            (mobile.Id, renter.Id, "Savršeno, rezervišemo. Hvala na informacijama!",                                                          now.AddHours(-1)),
        });

        // ── Conversation 2: mobile ↔ admin about Luksuzni stan Sarajevo ───────
        await AddConversation(db, mobile, admin, props[0], now.AddDays(-3), new[]
        {
            (mobile.Id, admin.Id, "Dobar dan! Zanima me stan u centru Sarajeva za juni. Da li je dostupan od 1. do 8. juna?",                  now.AddDays(-3)),
            (admin.Id, mobile.Id, "Dobar dan! Da, stan je slobodan u tom periodu. Cijena je 1200 KM/miesec.",                                  now.AddDays(-3).AddHours(1)),
            (mobile.Id, admin.Id, "Odlično! Je li parking uključen u cijenu?",                                                                 now.AddDays(-2)),
            (admin.Id, mobile.Id, "Nažalost, parking nije uključen, ali postoji javna garaža 100m od stana za 5 KM/dan. Platite unaprijed?",   now.AddDays(-2).AddHours(2)),
            (mobile.Id, admin.Id, "Razumijem, hvala. Izvršio sam rezervaciju putem platforme.",                                                 now.AddDays(-1)),
        });

        // ── Conversation 3: mobile ↔ renter about Studio Neretva ──────────────
        await AddConversation(db, mobile, renter, props[8], now.AddDays(-1), new[]
        {
            (mobile.Id, renter.Id, "Pozdrav, da li studio ima klimu? Planiram boravak u julu.",                                                now.AddDays(-1)),
            (renter.Id, mobile.Id, "Zdravo! Da, studio ima klima uređaj i WiFi. Pogled na Neretvu je prelijep u ljetnim večerima.",            now.AddDays(-1).AddHours(1)),
            (mobile.Id, renter.Id, "Zvuči odlično! Rezervišem za 1-4. jula. Hvala!",                                                          now.AddDays(-1).AddHours(2)),
        });

        // ── Conversation 4: mobile ↔ admin about Kuća sa vrtom Tuzla ─────────
        await AddConversation(db, mobile, admin, props[3], now.AddDays(-7), new[]
        {
            (mobile.Id, admin.Id, "Koliko gostiju može primiti kuća u Tuzli?",                                                                 now.AddDays(-7)),
            (admin.Id, mobile.Id, "Kuća prima do 8 gostiju, ima 5 soba i 2 kupatila. Idealna za porodični odmor.",                             now.AddDays(-7).AddHours(3)),
            (mobile.Id, admin.Id, "Hvala, ovo je savršeno za naš izlet!",                                                                      now.AddDays(-6)),
        });

        logger.LogInformation("Seeded 4 conversations.");
    }

    private static async Task AddConversation(
        DatabaseContext db,
        ApplicationUser client,
        ApplicationUser renter,
        Property property,
        DateTime createdAt,
        (int SenderId, int RecipientId, string Content, DateTime SentAt)[] messages)
    {
        var conv = new Conversation
        {
            ClientId    = client.Id,
            RenterId    = renter.Id,
            PropertyId  = property.Id,
            LastMessage = messages.Last().Content,
            LastSent    = messages.Last().SentAt,
            CreatedAt   = createdAt,
        };
        db.Conversations.Add(conv);
        await db.SaveChangesAsync();

        foreach (var (senderId, recipientId, content, sentAt) in messages)
        {
            db.Messages.Add(new Message
            {
                ConversationId = conv.Id,
                SenderId       = senderId,
                RecipientId    = recipientId,
                Content        = content,
                IsRead         = sentAt < DateTime.UtcNow.AddHours(-1),
                CreatedAt      = sentAt,
            });
        }
        await db.SaveChangesAsync();
    }

    // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

    private static async Task SeedNotificationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger,
        string webRootPath)
    {
        if (await db.Notifications.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var admin  = await userManager.FindByNameAsync("desktop");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var uploadsDir = Path.Combine(webRootPath, "uploads", "images");
        Directory.CreateDirectory(uploadsDir);

        var now = DateTime.UtcNow;

        async Task<(string? url, byte[]? bytes)> NotifImage(int seed)
        {
            var imgUrl  = $"https://picsum.photos/seed/{seed}/400/300";
            var bytes   = await DownloadImageAsync(imgUrl, logger);
            if (bytes == null) return (null, null);
            var fileName = $"notif_{seed}_{Guid.NewGuid():N}.jpg";
            var filePath = Path.Combine(uploadsDir, fileName);
            await File.WriteAllBytesAsync(filePath, bytes);
            return ($"/uploads/images/{fileName}", bytes);
        }

        var (img300Url, img300Bytes) = await NotifImage(300);
        var (img301Url, img301Bytes) = await NotifImage(301);
        var (img302Url, img302Bytes) = await NotifImage(302);

        db.Notifications.AddRange(

            // ── Mobile (client) notifications ─────────────────────────────────
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Dobrodošli u PropertEase!",
                Text      = "Hvala što ste se prijavili. Pregledajte naše ponude nekretnina i pronađite savršen smještaj za vaš odmor ili posao.",
                Image     = img300Url,
                ImageBytes = img300Bytes,
                CreatedAt = now.AddDays(-10),
            },
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Proljetna akcija – popusti do 20%",
                Text      = "Iskoristite proljetnu sezonu! Odabrane nekretnine imaju popust do 20% za rezervacije u aprilu i maju. Ne propustite!",
                Image     = img301Url,
                ImageBytes = img301Bytes,
                CreatedAt = now.AddDays(-5),
            },
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Vaša recenzija je objavljena",
                Text      = "Hvala na ocjeni nekretnine 'Vila Blagaj'. Vaša recenzija pomaže drugim korisnicima da donesu bolju odluku.",
                CreatedAt = now.AddDays(-2),
            },
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Podsjetnik: nadolazeći check-in",
                Text      = "Podsjetnik: vaš check-in za Studio Bašćaršija je za 10 dana (01.05.2026). Sretno putovanje!",
                CreatedAt = now.AddDays(-1),
            },

            // ── Renter notifications ───────────────────────────────────────────
            new Notification
            {
                UserId    = renter.Id,
                Name      = "Nova ocjena nekretnine",
                Text      = "Korisnik 'Mobilni Korisnik' je ostavio ocjenu 5★ za vašu nekretninu 'Vila Blagaj'. Odlično!",
                Image     = img302Url,
                ImageBytes = img302Bytes,
                CreatedAt = now.AddDays(-2),
            },
            new Notification
            {
                UserId    = renter.Id,
                Name      = "Vaša nekretnina je popularna!",
                Text      = "Apartman Mostar Stari Grad je pregledan 47 puta ovog tjedna. Razmislite o ažuriranju fotografija za još veću vidljivost.",
                CreatedAt = now.AddDays(-4),
            },
            new Notification
            {
                UserId    = renter.Id,
                Name      = "Plaćanje primljeno",
                Text      = "Primili ste plaćanje od 1800 KM za rezervaciju #0002 (Vila Blagaj, 10-30. april). Iznos je dostupan na vašem računu.",
                CreatedAt = now.AddDays(-15),
            },

            // ── Admin notifications ────────────────────────────────────────────
            new Notification
            {
                UserId    = admin.Id,
                Name      = "Novi korisnik registriran",
                Text      = "Korisnik 'Mobilni Korisnik' (mobile@propertease.test) se registrirao na platformu. Provjerite profil po potrebi.",
                CreatedAt = now.AddDays(-10),
            },
            new Notification
            {
                UserId    = admin.Id,
                Name      = "Tjedni izvještaj",
                Text      = "Ovaj tjedan je kreirano 3 novih rezervacija, od čega su 2 plaćene. Ukupan prihod: 2115 KM. Detalje pogledajte u izvještajima.",
                CreatedAt = now.AddDays(-3),
            }
        );

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded notifications for all users.");
    }

    // ─── HELPERS ──────────────────────────────────────────────────────────────

    private static async Task<byte[]?> DownloadImageAsync(string url, ILogger logger)
    {
        try
        {
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("PropertEase-Seeder/1.0");
            return await client.GetByteArrayAsync(url);
        }
        catch (Exception ex)
        {
            logger.LogWarning("Could not download image from {Url}: {Msg}", url, ex.Message);
            return null;
        }
    }

    private record PropertyDef(
        string Name, int OwnerId, int TypeId, int CityId, string Description,
        int Rooms, int Baths, int Sqm, int Cap,
        float Monthly, float Daily, bool IsMonthlyRental,
        bool WiFi, bool Furnished, bool Balcony, bool Pool, bool AC,
        double Lat, double Lng);
}
