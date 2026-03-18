using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.ApplicationUsersRepository
{
    public interface IApplicationUsersRepository: IBaseRepository<ApplicationUser, int>
    {
        Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string UserName);
        new Task<List<ApplicationUserDto>> GetAllAsync();

        Task<PropertEase.Core.Dto.PagedResult<ApplicationUserDto>> GetFiltered(UserFilter filter);
        new Task<List<ApplicationUserDto>> GetEmployees();
        Task<ApplicationUserDto> GetByIdAsync(int id);
        new Task<List<ApplicationUserDto>> GetClients();
        Task<List<ApplicationUserDto>> GetAdminsAsync();
        Task<List<ApplicationUserDto>> GetRenters();
    }
}
