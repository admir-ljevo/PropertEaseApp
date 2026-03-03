using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MobiFon.Core.Entities;
using MobiFon.Core.Entities.Identity;
using MobiFon.Infrastructure.Configurations;

namespace MobiFon.Infrastructure
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


        public DatabaseContext(DbContextOptions<DatabaseContext> options) : base(options)
        {

        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

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
                e.HasIndex(r => r.IsActive);
                e.HasIndex(r => new { r.DateOfOccupancyStart, r.DateOfOccupancyEnd });
            });

            modelBuilder.Entity<PropertyRating>(e =>
            {
                e.HasIndex(r => r.PropertyId);
                e.HasIndex(r => r.ReviewerId);
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
            });

            modelBuilder.Entity<Photo>(e =>
            {
                e.HasIndex(p => p.PropertyId);
            });

            modelBuilder.Entity<Notification>(e =>
            {
                e.HasIndex(n => n.UserId);
            });
        }

    }
}
