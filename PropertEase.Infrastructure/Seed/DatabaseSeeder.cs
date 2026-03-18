using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Entities;
using PropertEase.Core.Entities.Identity;

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
            await SeedRatingsAsync(db, userManager, logger);
            await SeedProfilePhotosAsync(db, userManager, logger);
            await SeedConversationsAsync(db, userManager, logger);
            await SeedNotificationsAsync(db, userManager, logger);
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
        }, password: "test", roles: new[] { "Admin", "Renter" }, firstName: "Admin", lastName: "Korisnik", city: city);

        await EnsureUser(userManager, hasher, db, logger, new ApplicationUser
        {
            UserName       = "mobile",
            Email          = "mobile@propertease.test",
            EmailConfirmed = true,
            Active         = true,
        }, password: "test", roles: new[] { "Client" }, firstName: "Mobilni", lastName: "Korisnik", city: city);

        await EnsureUser(userManager, hasher, db, logger, new ApplicationUser
        {
            UserName       = "izdavac",
            Email          = "izdavac@propertease.test",
            EmailConfirmed = true,
            Active         = true,
        }, password: "test", roles: new[] { "Renter" }, firstName: "Marko", lastName: "Izdavač", city: city);
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
        City? city)
    {
        var existing = await userManager.FindByNameAsync(user.UserName!);
        if (existing != null)
        {
            existing.PasswordHash = hasher.HashPassword(existing, password);
            existing.Active       = true;
            await userManager.UpdateAsync(existing);

            foreach (var role in roles)
                if (!await userManager.IsInRoleAsync(existing, role))
                    await userManager.AddToRoleAsync(existing, role);

            if (!await db.Persons.AnyAsync(p => p.ApplicationUserId == existing.Id))
            {
                db.Persons.Add(MakePerson(firstName, lastName, existing.Id, city));
                await db.SaveChangesAsync();
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

        db.Persons.Add(MakePerson(firstName, lastName, user.Id, city));
        await db.SaveChangesAsync();

        logger.LogInformation("Seeded user '{Username}' with roles '{Roles}'.", user.UserName, string.Join(", ", roles));
    }

    private static Person MakePerson(string firstName, string lastName, int userId, City? city) =>
        new Person
        {
            FirstName          = firstName,
            LastName           = lastName,
            BirthDate          = new DateTime(1990, 1, 1),
            BirthPlaceId       = city?.Id,
            ApplicationUserId  = userId,
            Address            = "Testna ulica 1",
            PostCode           = "71000",
            CreatedAt          = DateTime.UtcNow,
        };

    // ─── PROPERTIES ───────────────────────────────────────────────────────────

    private static async Task SeedPropertiesAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger,
        string webRootPath)
    {
        if (await db.Properties.AnyAsync()) return;

        var admin   = await userManager.FindByNameAsync("desktop");
        var renter  = await userManager.FindByNameAsync("izdavac");
        if (admin == null || renter == null) return;

        var sarajevo   = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Sarajevo");
        var mostar     = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Mostar");
        var banjaLuka  = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Banja Luka");
        var tuzla      = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Tuzla");
        var zenica     = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Zenica");

        var stan       = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Stan");
        var kuca       = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Kuća");
        var villa      = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Villa");
        var studio     = await db.PropertyTypes.FirstOrDefaultAsync(t => t.Name == "Studio");

        // PropertyDef positional order:
        // Name, OwnerId, TypeId, CityId, Description, Rooms, Baths, Sqm, Cap,
        // Monthly, Daily, IsMonthlyRental, WiFi, Furnished, Balcony, Pool, AC, Lat, Lng
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
            new PropertyDef("Vila Blagaj",                   renter.Id, villa!.Id,  mostar!.Id,
                "Autentična vila u srcu Blagaja, uz izvor Bune.",
                4, 2, 140, 8, 0f,    90f,   false, true,  true,  true,  true,  true,  43.2625, 17.9057),
            new PropertyDef("Apartman Mostar Stari Grad",    renter.Id, stan.Id,    mostar.Id,
                "Tradicionalni apartman uz Stari most, pogled na Neretvu.",
                2, 1, 70,  4, 850f,  0f,    true,  true,  true,  true,  false, false, 43.3372, 17.8138),
            new PropertyDef("Kuća Radobolja",                renter.Id, kuca.Id,    mostar.Id,
                "Mirna seoska kuća uz rijeku Radobolju, idealna za odmor.",
                3, 2, 120, 6, 0f,    55f,   false, false, false, false, false, false, 43.3100, 17.8200),
            new PropertyDef("Studio Neretva",                renter.Id, studio.Id,  mostar.Id,
                "Kompaktan studio s pogledom na rijeku Neretvu.",
                1, 1, 40,  2, 0f,    40f,   false, true,  true,  false, false, true,  43.3464, 17.8077),
            new PropertyDef("Luksuzna villa Sarajevo Ilidža", renter.Id, villa.Id,   sarajevo.Id,
                "Moderna luksuzna villa na Ilidži s bazenom i teniskim terenom.",
                6, 4, 280, 10, 0f,   180f,  false, true,  true,  true,  true,  true,  43.8270, 18.3100),
        };

        // Picsum seeds – one per property, each property gets 3 images (seed, seed+1, seed+2)
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
            await db.SaveChangesAsync();   // need Id before adding photos

            for (int j = 0; j < 3; j++)
            {
                int seed      = picsumSeeds[i] + j;
                var imageUrl  = $"https://picsum.photos/seed/{seed}/800/600";
                var bytes     = await DownloadImageAsync(imageUrl, logger);
                var fileName  = $"property{property.Id}_img{j + 1}_{Guid.NewGuid():N}.jpg";
                var filePath  = Path.Combine(uploadsDir, fileName);
                var urlPath   = $"/uploads/images/{fileName}";

                if (bytes != null)
                {
                    await File.WriteAllBytesAsync(filePath, bytes);
                }

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

        var mobile  = await userManager.FindByNameAsync("mobile");
        var admin   = await userManager.FindByNameAsync("desktop");
        var renter  = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var adminProperties  = await db.Properties.Where(p => p.ApplicationUserId == admin.Id  && !p.IsDeleted).ToListAsync();
        var renterProperties = await db.Properties.Where(p => p.ApplicationUserId == renter.Id && !p.IsDeleted).ToListAsync();

        if (adminProperties.Count == 0 && renterProperties.Count == 0) return;

        var reservations = new List<(Property property, int renterId, DateTime start, int days)>
        {
            (adminProperties.ElementAtOrDefault(0)  ?? renterProperties[0], admin.Id,  new DateTime(2025, 6, 1),  7),
            (adminProperties.ElementAtOrDefault(1)  ?? renterProperties[0], admin.Id,  new DateTime(2025, 7, 15), 5),
            (renterProperties.ElementAtOrDefault(0) ?? adminProperties[0],  renter.Id, new DateTime(2025, 8, 10), 10),
            (renterProperties.ElementAtOrDefault(1) ?? adminProperties[0],  renter.Id, new DateTime(2025, 9, 1),  3),
        };

        int counter = 1;
        foreach (var (prop, renterId, start, days) in reservations)
        {
            bool isMonthly = prop.IsMonthly;
            int months = isMonthly ? Math.Max(1, days / 30) : 0;
            float totalPrice = isMonthly
                ? (prop.MonthlyPrice ?? 500f) * months
                : (prop.DailyPrice  ?? 60f)  * days;
            db.PropertyReservations.Add(new PropertyReservation
            {
                ReservationNumber    = $"RES-SEED-{counter:D4}",
                PropertyId           = prop.Id,
                RenterId             = renterId,
                ClientId             = mobile.Id,
                NumberOfGuests       = 2,
                DateOfOccupancyStart = start,
                DateOfOccupancyEnd   = isMonthly ? start.AddMonths(months) : start.AddDays(days),
                NumberOfDays         = isMonthly ? 0 : days,
                NumberOfMonths       = months,
                TotalPrice           = totalPrice,
                IsDaily              = !isMonthly,
                IsMonthly            = isMonthly,
                IsActive             = false,
                Description          = "Seeded reservation",
                CreatedAt            = DateTime.UtcNow,
            });
            counter++;
        }
        await db.SaveChangesAsync();
        logger.LogInformation("Seeded {Count} reservations for user 'mobile'.", counter - 1);
    }

    // ─── RATINGS ──────────────────────────────────────────────────────────────

    private static async Task SeedRatingsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.PropertyRatings.AnyAsync() || await db.UserRatings.AnyAsync()) return;

        var mobile  = await userManager.FindByNameAsync("mobile");
        var admin   = await userManager.FindByNameAsync("desktop");
        var renter  = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || admin == null || renter == null) return;

        var properties = await db.Properties.Where(p => !p.IsDeleted).Take(4).ToListAsync();
        if (properties.Count == 0) return;

        // Property ratings – mobile reviews properties
        var propertyRatings = new[]
        {
            (prop: properties.ElementAtOrDefault(0), rating: 4.5, desc: "Odličan stan, čisto i uredno. Preporučujem!"),
            (prop: properties.ElementAtOrDefault(1), rating: 5.0, desc: "Fantastičan smještaj, lokacija je savršena."),
            (prop: properties.ElementAtOrDefault(2), rating: 3.5, desc: "Dobar smještaj ali malo zastarjelo namještanje."),
            (prop: properties.ElementAtOrDefault(3), rating: 4.0, desc: "Ugodna vila, bazen je bonus. Sve u svemu odlično."),
        };

        foreach (var (prop, rating, desc) in propertyRatings)
        {
            if (prop == null) continue;
            db.PropertyRatings.Add(new PropertyRating
            {
                PropertyId   = prop.Id,
                ReviewerId   = mobile.Id,
                ReviewerName = "Mobilni Korisnik",
                Rating       = rating,
                Description  = desc,
                CreatedAt    = DateTime.UtcNow,
            });
        }

        // User ratings – mobile rates renter and admin
        db.UserRatings.Add(new UserRating
        {
            RenterId     = renter.Id,
            ReviewerId   = mobile.Id,
            ReviewerName = "Mobilni Korisnik",
            Rating       = 4.5,
            Description  = "Vrlo komunikativan i profesionalan izdavač.",
            CreatedAt    = DateTime.UtcNow,
        });
        db.UserRatings.Add(new UserRating
        {
            RenterId     = admin.Id,
            ReviewerId   = mobile.Id,
            ReviewerName = "Mobilni Korisnik",
            Rating       = 5.0,
            Description  = "Izvrsna usluga i brz odgovor na sve upite.",
            CreatedAt    = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded property and user ratings.");
    }

    // ─── PROFILE PHOTOS ───────────────────────────────────────────────────────

    private static async Task SeedProfilePhotosAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        var users = new[] { "desktop", "mobile", "izdavac" };
        int[] picsumSeeds = { 200, 201, 202 };

        for (int i = 0; i < users.Length; i++)
        {
            var user = await userManager.FindByNameAsync(users[i]);
            if (user == null) continue;

            var person = await db.Persons.FirstOrDefaultAsync(p => p.ApplicationUserId == user.Id);
            if (person == null || person.ProfilePhoto != null) continue;

            var url   = $"https://picsum.photos/seed/{picsumSeeds[i]}/200/200";
            var bytes = await DownloadImageAsync(url, logger);
            if (bytes == null) continue;

            var fileName  = $"avatar_{users[i]}_{Guid.NewGuid():N}.jpg";
            person.ProfilePhoto      = $"/uploads/images/{fileName}";
            person.ProfilePhotoBytes = bytes;
        }

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded profile photos for users.");
    }

    // ─── CONVERSATIONS ─────────────────────────────────────────────────────────

    private static async Task SeedConversationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.Conversations.AnyAsync()) return;

        var mobile  = await userManager.FindByNameAsync("mobile");
        var renter  = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || renter == null) return;

        var property = await db.Properties
            .FirstOrDefaultAsync(p => p.ApplicationUserId == renter.Id && !p.IsDeleted);
        if (property == null) return;

        var now = DateTime.UtcNow;
        var messages = new[]
        {
            (SenderId: mobile.Id,  RecipientId: renter.Id,  Content: "Pozdrav! Da li je nekretnina slobodna u periodu 1-7. aprila?",                           SentAt: now.AddHours(-5)),
            (SenderId: renter.Id,  RecipientId: mobile.Id,  Content: "Zdravo! Da, nekretnina je slobodna u tom periodu. Cijena je 90 KM po noći.",             SentAt: now.AddHours(-4)),
            (SenderId: mobile.Id,  RecipientId: renter.Id,  Content: "Odlično! Da li je moguće early check-in oko 11h?",                                        SentAt: now.AddHours(-3)),
            (SenderId: renter.Id,  RecipientId: mobile.Id,  Content: "Nažalost, standardni check-in je od 14h. Ako stignu ranijе, prtljag mogu ostaviti kod nas.", SentAt: now.AddHours(-2)),
            (SenderId: mobile.Id,  RecipientId: renter.Id,  Content: "Razumijem, hvala na informaciji. Rezervišemo!",                                           SentAt: now.AddHours(-1)),
        };

        var conversation = new Conversation
        {
            ClientId    = mobile.Id,
            RenterId    = renter.Id,
            PropertyId  = property.Id,
            LastMessage = messages.Last().Content,
            LastSent    = messages.Last().SentAt,
            CreatedAt   = messages.First().SentAt,
        };
        db.Conversations.Add(conversation);
        await db.SaveChangesAsync();

        foreach (var m in messages)
        {
            db.Messages.Add(new Message
            {
                ConversationId = conversation.Id,
                SenderId       = m.SenderId,
                RecipientId    = m.RecipientId,
                Content        = m.Content,
                IsRead         = false,
                CreatedAt      = m.SentAt,
            });
        }
        await db.SaveChangesAsync();
        logger.LogInformation("Seeded 1 conversation with {Count} messages.", messages.Length);
    }

    // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

    private static async Task SeedNotificationsAsync(
        DatabaseContext db,
        UserManager<ApplicationUser> userManager,
        ILogger logger)
    {
        if (await db.Notifications.AnyAsync()) return;

        var mobile = await userManager.FindByNameAsync("mobile");
        var renter = await userManager.FindByNameAsync("izdavac");
        if (mobile == null || renter == null) return;

        var now = DateTime.UtcNow;

        db.Notifications.AddRange(
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Dobrodošli u PropertEase!",
                Text      = "Hvala što ste se prijavili. Pregledajte naše ponude nekretnina i pronađite savršen smještaj za vaš odmor.",
                CreatedAt = now.AddDays(-3),
            },
            new Notification
            {
                UserId    = mobile.Id,
                Name      = "Nova promocija – proljetni popusti",
                Text      = "Iskoristite proljetnu sezonu! Odabrane nekretnine imaju popust do 20% za rezervacije u aprilu i maju.",
                CreatedAt = now.AddDays(-1),
            },
            new Notification
            {
                UserId    = renter.Id,
                Name      = "Vaša nekretnina je dobila novu ocjenu",
                Text      = "Korisnik 'Mobilni Korisnik' je ostavio ocjenu 5★ za vašu nekretninu. Provjerite recenziju!",
                CreatedAt = now.AddHours(-6),
            }
        );

        await db.SaveChangesAsync();
        logger.LogInformation("Seeded notifications.");
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
