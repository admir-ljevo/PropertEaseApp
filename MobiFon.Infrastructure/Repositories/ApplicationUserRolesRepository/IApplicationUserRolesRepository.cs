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
    public interface IApplicationUserRolesRepository: IBaseRepository<ApplicationUserRole, int>
    {
        public Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int userId);
    }
}
