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
    public interface IApplicationUserRolesRepository: IBaseRepository<ApplicationUserRole, int>
    {
        public Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int userId);
        public Task AddUserRoleAsync(int userId, int roleId);
        public Task RemoveUserRoleAsync(int userRoleId);
        public Task RemoveUserRoleByUserAndRoleAsync(int userId, int roleId);
    }
}
