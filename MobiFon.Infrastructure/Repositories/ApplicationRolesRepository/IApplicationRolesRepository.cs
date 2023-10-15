using MobiFon.Core.Dto.ApplicationRole;
using MobiFon.Core.Entities.Identity;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.ApplicationRolesRepository
{
    public interface IApplicationRolesRepository: IBaseRepository<ApplicationRole, int>
    {
        Task<ApplicationRoleDto> GetByRoleLevelOrName(int roleLevelId, string roleName);
        new Task<List<ApplicationRoleDto>> GetAllAsync();
    }
}
