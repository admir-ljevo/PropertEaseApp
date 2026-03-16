using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PropertEase.Core.Entities.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Configurations
{
    internal class ApplicationUserRoleEntityTypeConfiguration: BaseEntityTypeConfiguration<ApplicationUserRole>
    {
        public override void Configure(EntityTypeBuilder<ApplicationUserRole> builder)
        {
            builder.HasKey(ur => new { ur.UserId, ur.RoleId });
            builder.Property(ur => ur.Id).ValueGeneratedOnAdd();
            builder.HasQueryFilter(x => !x.IsDeleted);

            builder.HasOne(ur => ur.User)
                .WithMany(us => us.Roles)
                .HasForeignKey(ur => ur.UserId);

            builder.HasOne(ur => ur.Role)
                .WithMany(us => us.Roles)
                .HasForeignKey(ur => ur.RoleId);
        }
    }
}
