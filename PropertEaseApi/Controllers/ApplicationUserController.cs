using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.ApplicationUserRolesService;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Core.Filters;
using PropertEase.Shared.Constants;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = AppRoles.Admin)]
    public class ApplicationUserController : ControllerBase
    {
        private readonly IApplicationUsersService _usersService;
        private readonly IApplicationUserRolesService _userRolesService;
        private readonly IFileManager _fileManager;

        public ApplicationUserController(
            IFileManager fileManager,
            IApplicationUsersService usersService,
            IApplicationUserRolesService userRolesService)
        {
            _fileManager = fileManager;
            _usersService = usersService;
            _userRolesService = userRolesService;
        }

        [HttpGet("GetAllUsers")]
        public async Task<IActionResult> GetAllUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            pageSize = Paging.Clamp(pageSize);
            var result = await _usersService.GetFiltered(new UserFilter { Page = page, PageSize = pageSize });
            return Ok(result);
        }

        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] UserFilter filter)
        {
            var users = await _usersService.GetFiltered(filter);
            return Ok(users);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var user = await _usersService.GetByIdAsync(id);
            return Ok(user);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _usersService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("{userId}/roles")]
        public async Task<IActionResult> GetUserRoles(int userId)
        {
            var roles = await _userRolesService.GetByUserId(userId);
            return Ok(roles);
        }

        [HttpPost("{userId}/roles")]
        public async Task<IActionResult> AssignRole(int userId, [FromBody] ApplicationUserRoleDto dto)
        {
            await _userRolesService.AssignRoleAsync(userId, dto.RoleId);
            return Ok();
        }

        [HttpDelete("{userId}/roles/{roleId}")]
        public async Task<IActionResult> RemoveRole(int userId, int roleId)
        {
            await _userRolesService.RemoveRoleAsync(userId, roleId);
            return Ok();
        }
    }
}
