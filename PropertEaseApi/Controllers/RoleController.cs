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
            try
            {
                var roles = await applicationRolesService.GetAllAsync();
                return Ok(roles.Take(100));
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpGet("GetFilteredData")]
        public async Task<IActionResult> GetFilteredData([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                var all = await applicationRolesService.GetAllAsync();
                var filtered = string.IsNullOrWhiteSpace(search)
                    ? all
                    : all.Where(x => x.Name != null && x.Name.Contains(search, StringComparison.OrdinalIgnoreCase)).ToList();
                var totalCount = filtered.Count;
                var items = filtered.Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { items, totalCount });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost]
        public async Task<IActionResult> Post([FromBody] ApplicationRoleDto roleDto)
        {
            try
            {
                var result = await applicationRolesService.AddAsync(roleDto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                await applicationRolesService.RemoveByIdAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }
    }
}
