using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Entities.Identity;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.ApplicationUsersRepository
{
    public interface IApplicationUsersRepository: IBaseRepository<ApplicationUser, int>
    {
        Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string UserName);
        new Task<List<ApplicationUserDto>> GetAllAsync();

        Task<List<ApplicationUserDto>> GetFiltered(UserFilter filter);
        new Task<List<ApplicationUserDto>> GetEmployees();
        Task<ApplicationUserDto> GetByIdAsync(int id);
        new Task<List<ApplicationUserDto>> GetClients();
    }
}
