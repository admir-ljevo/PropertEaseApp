using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Services.Services.BaseService;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Filters;

namespace PropertEase.Services.Services.ApplicationUsersService
{
    public interface IApplicationUsersService: IBaseService<ApplicationUserDto>
    {
        Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string pUserName);
        Task<ApplicationUserDto> AddEmployeeAsync(EmployeeInsertDto newUser);
        Task<ApplicationUserDto> AddClientAsync(ClientInsertDto newUser);
        Task<List<ApplicationUserDto>> GetAllAsync();
        Task<PropertEase.Core.Dto.PagedResult<ApplicationUserDto>> GetFiltered(UserFilter filter);
        Task<List<ApplicationUserDto>> GetEmployees();
        Task<List<ApplicationUserDto>> GetClients();
        Task<List<ApplicationUserDto>> GetRenters();
        Task<ApplicationUserDto> EditEmployee(EmployeeUpdateDto user);
        Task<ApplicationUserDto> EditClient(ClientUpdateDto user);
        Task<ApplicationUserDto> GetByIdAsync(int id);

        Task ChangePhoto(ApplicationUserDto entityDto);
    }
}
