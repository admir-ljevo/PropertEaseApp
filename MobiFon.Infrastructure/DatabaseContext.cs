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


            //SeedData(modelBuilder);
        }

    }
}
