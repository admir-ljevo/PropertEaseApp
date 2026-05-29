using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Services.Services.ApplicationRolesService;
using PropertEase.Shared.Constants;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class RoleController : ControllerBase
    {
        public IApplicationRolesService applicationRolesService;
        public RoleController(IApplicationRolesService applicationRolesService)
        {
            this.applicationRolesService = applicationRolesService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAsync()
        {
            var roles = await applicationRolesService.GetAllAsync();
            return Ok(roles.Take(100));
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var (items, totalCount) = await applicationRolesService.GetFilteredAsync(search, page, pageSize);
            return Ok(new { items, totalCount });
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost]
        public async Task<IActionResult> Post([FromBody] ApplicationRoleDto roleDto)
        {
            var result = await applicationRolesService.AddAsync(roleDto);
            return Ok(result);
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await applicationRolesService.RemoveByIdAsync(id);
            return Ok();
        }
    }
}
