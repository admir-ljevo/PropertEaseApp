using AutoMapper;
using MobiFon.Core.Dto;
using MobiFon.Core.Entities.Identity;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.ApplicationUserRolesRepository
{
    public class ApplicationUserRolesRepository : BaseRepository<ApplicationUserRole, int>, IApplicationUserRolesRepository
    {
        public ApplicationUserRolesRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int userId)
        {
            return await ProjectToListAsync<ApplicationUserRoleDto>(DatabaseContext.UserRoles.Where(ur=>userId == ur.UserId));
        }
    }
}
