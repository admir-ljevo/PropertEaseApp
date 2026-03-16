using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.ApplicationRolesService
{
    public interface IApplicationRolesService: IBaseService<ApplicationRoleDto>
    {
        Task<ApplicationRoleDto> GetByRoleLevelIdOrName(int roleLeveleId, string roleName);

    }
}
