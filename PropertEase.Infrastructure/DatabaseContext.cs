using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PropertEase.Core.Entities;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Configurations;

namespace PropertEase.Infrastructure
{
    public partial class DatabaseContext: IdentityDbContext<ApplicationUser, ApplicationRole, int, ApplicationUserClaim, ApplicationUserRole, ApplicationUserLogin, ApplicationRoleClaim, ApplicationUserToken>
    {
        public DbSet<Country> Countries { get; set; }   
        public DbSet<City> Cities { get; set; } 
        public DbSet<Person> Persons { get; set; }
        public DbSet<Photo> Photos { get; set; }
        public DbSet<Property> Properties { get; set; }
        public DbSet<PropertyRating> PropertyRatings { get; set; }
        public DbSet<PropertyType> PropertyTypes { get; set; }  
        public DbSet<PropertyReservation> PropertyReservations { get; set; }  
        public DbSet<Message> Messages { get; set; }  
        public DbSet<Conversation> Conversations { get; set; }  
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<ReservationNotification> ReservationNotifications { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<UserRating> UserRatings { get; set; }


        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options)
        {

        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // These four Identity tables are never written to by this application.
            // ExcludeFromMigrations prevents EF from recreating them after they are dropped.
            modelBuilder.Entity<ApplicationUserClaim>().ToTable("AspNetUserClaims", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<ApplicationUserLogin>().ToTable("AspNetUserLogins", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<ApplicationRoleClaim>().ToTable("AspNetRoleClaims", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<ApplicationUserToken>().ToTable("AspNetUserTokens", t => t.ExcludeFromMigrations());

            modelBuilder.ApplyConfigurationsFromAssembly(typeof(BaseEntityTypeConfiguration<>).Assembly);

            // Indexes for frequently filtered/joined FK columns
            modelBuilder.Entity<Property>(e =>
            {
                e.HasIndex(p => p.CityId);
                e.HasIndex(p => p.PropertyTypeId);
                e.HasIndex(p => p.ApplicationUserId);
                e.HasIndex(p => p.IsAvailable);
                e.HasIndex(p => p.IsDeleted);
            });

            modelBuilder.Entity<PropertyReservation>(e =>
            {
                e.HasIndex(r => r.PropertyId);
                e.HasIndex(r => r.ClientId);
                e.HasIndex(r => r.RenterId);
                e.HasIndex(r => r.Status);
                e.HasIndex(r => new { r.DateOfOccupancyStart, r.DateOfOccupancyEnd });
            });

            modelBuilder.Entity<PropertyRating>(e =>
            {
                e.HasIndex(r => r.PropertyId);
                e.HasIndex(r => r.ReviewerId);
                e.HasIndex(r => r.ReservationId);
                e.HasIndex(r => new { r.ReviewerId, r.ReservationId })
                    .IsUnique()
                    .HasFilter("[ReservationId] IS NOT NULL");
                e.HasOne(r => r.Reservation)
                    .WithMany()
                    .HasForeignKey(r => r.ReservationId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<UserRating>(e =>
            {
                e.HasIndex(r => r.RenterId);
                e.HasIndex(r => r.ReviewerId);
                e.HasIndex(r => r.ReservationId);
                e.HasIndex(r => new { r.ReviewerId, r.ReservationId })
                    .IsUnique()
                    .HasFilter("[ReservationId] IS NOT NULL");
                e.HasOne(r => r.Renter)
                    .WithMany()
                    .HasForeignKey(r => r.RenterId)
                    .OnDelete(DeleteBehavior.NoAction);
                e.HasOne(r => r.Reviewer)
                    .WithMany()
                    .HasForeignKey(r => r.ReviewerId)
                    .OnDelete(DeleteBehavior.NoAction);
                e.HasOne(r => r.Reservation)
                    .WithMany()
                    .HasForeignKey(r => r.ReservationId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            modelBuilder.Entity<Conversation>(e =>
            {
                e.HasIndex(c => c.PropertyId);
                e.HasIndex(c => c.ClientId);
                e.HasIndex(c => c.RenterId);
            });

            modelBuilder.Entity<Message>(e =>
            {
                e.HasIndex(m => m.ConversationId);
                e.HasIndex(m => m.SenderId);
                e.HasIndex(m => m.RecipientId);
                e.HasIndex(m => new { m.RecipientId, m.IsRead });
            });

            modelBuilder.Entity<Photo>(e =>
            {
                e.HasIndex(p => p.PropertyId);
            });

            modelBuilder.Entity<Notification>(e =>
            {
                e.HasIndex(n => n.UserId);
            });

            modelBuilder.Entity<Payment>(e =>
            {
                e.HasIndex(p => p.ClientId);
                e.HasIndex(p => p.ReservationId);
            });

            modelBuilder.Entity<ReservationNotification>(e =>
            {
                e.HasIndex(n => n.UserId);
                e.HasIndex(n => new { n.UserId, n.IsSeen });
            });
        }

    }
}
