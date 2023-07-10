using MobiFon.Core.Dto;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.ApplicationUserRolesService
{
    public interface IApplicationUserRolesService : IBaseService<ApplicationUserRoleDto>
    {
        Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int pUserId);
    }
}
