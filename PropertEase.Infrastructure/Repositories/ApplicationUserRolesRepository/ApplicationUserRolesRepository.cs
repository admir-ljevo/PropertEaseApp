using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.ApplicationUserRolesRepository
{
    public class ApplicationUserRolesRepository : BaseRepository<ApplicationUserRole, int>, IApplicationUserRolesRepository
    {
        public ApplicationUserRolesRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int userId)
        {
            return await ProjectToListAsync<ApplicationUserRoleDto>(
                DatabaseContext.UserRoles.Where(ur => ur.UserId == userId && !ur.IsDeleted));
        }

        public async Task AddUserRoleAsync(int userId, int roleId)
        {
            var existing = await DatabaseContext.UserRoles
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == roleId);

            if (existing != null)
            {
                existing.IsDeleted = false;
                existing.ModifiedAt = DateTime.Now;
                DatabaseContext.UserRoles.Update(existing);
            }
            else
            {
                var entity = new ApplicationUserRole
                {
                    UserId = userId,
                    RoleId = roleId,
                    CreatedAt = DateTime.Now,
                    IsDeleted = false
                };
                await DatabaseContext.UserRoles.AddAsync(entity);
            }
            await DatabaseContext.SaveChangesAsync();
        }

        public async Task RemoveUserRoleAsync(int userRoleId)
        {
            var entity = await DatabaseContext.UserRoles
                .FirstOrDefaultAsync(ur => ur.Id == userRoleId);
            if (entity == null) return;
            entity.IsDeleted = true;
            entity.ModifiedAt = DateTime.Now;
            DatabaseContext.UserRoles.Update(entity);
            await DatabaseContext.SaveChangesAsync();
        }

        public override async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await RemoveUserRoleAsync(id);
        }
    }
}
