using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Services.Services.BaseService;
using PropertEase.Core.Filters;

namespace MobiFon.Services.Services.ApplicationUsersService
{
    public interface IApplicationUsersService: IBaseService<ApplicationUserDto>
    {
        Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string pUserName);
        Task<ApplicationUserDto> AddEmployeeAsync(EmployeeInsertDto newUser);
        Task<ApplicationUserDto> AddClientAsync(ClientInsertDto newUser);
        Task<List<ApplicationUserDto>> GetAllAsync();
        Task<List<ApplicationUserDto>> GetFiltered(UserFilter filter);
        Task<List<ApplicationUserDto>> GetEmployees();
        Task<List<ApplicationUserDto>> GetClients();
        Task<ApplicationUserDto> EditEmployee(EmployeeInsertDto user);
        Task ChangePhoto(ApplicationUserDto entityDto);
    }
}
