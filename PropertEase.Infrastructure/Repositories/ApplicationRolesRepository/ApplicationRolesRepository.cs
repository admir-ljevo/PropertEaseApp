using AutoMapper;
using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.ApplicationRolesRepository
{
    public class ApplicationRolesRepository: BaseRepository<ApplicationRole, int>, IApplicationRolesRepository
    {
        public ApplicationRolesRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {

        }

        public async Task<ApplicationRoleDto> GetByRoleLevelOrName(int roleLevelId, string roleName)
        {
            var role = DatabaseContext.Roles.FirstOrDefault(c => c.RoleLevel == roleLevelId || c.Name == roleName);
            return Mapper.Map<ApplicationRoleDto>(role);
        }
        public async Task<List<ApplicationRoleDto>> GetAllAsync()
        {
           return await ProjectToListAsync<ApplicationRoleDto>(DatabaseContext.Roles.Where(x=>!x.IsDeleted));
            
        }
    }
}
