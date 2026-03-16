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
    public interface IApplicationRolesRepository: IBaseRepository<ApplicationRole, int>
    {
        Task<ApplicationRoleDto> GetByRoleLevelOrName(int roleLevelId, string roleName);
        new Task<List<ApplicationRoleDto>> GetAllAsync();
    }
}
