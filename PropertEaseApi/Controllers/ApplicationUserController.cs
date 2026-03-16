using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.ApplicationUserRolesService;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ApplicationUserController : ControllerBase
    {
        private readonly IApplicationUsersService ApplicationUsersService;
        private readonly IApplicationUserRolesService _userRolesService;
        private readonly IFileManager _fileManager;
        private readonly DatabaseContext _db;

        public ApplicationUserController(IFileManager fileManager, IApplicationUsersService applicationUsersService, IApplicationUserRolesService userRolesService, DatabaseContext db)
        {
            _fileManager = fileManager;
            ApplicationUsersService = applicationUsersService;
            _userRolesService = userRolesService;
            _db = db;
        }
        [HttpGet("GetAllUsers")]
        public async Task<IActionResult> GetAllUsers()
        {

            try
            {
                return Ok(await ApplicationUsersService.GetAllAsync());

            }
            catch (Exception err)
            {

                throw new Exception(err.Message);
            }

        }

        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] UserFilter filter)
        {
            try
            {
                var users = await ApplicationUsersService.GetFiltered(filter);
                return Ok(users);
            }
            catch (Exception ex)
            {

                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await ApplicationUsersService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("{userId}/roles")]
        public async Task<IActionResult> GetUserRoles(int userId)
        {
            try
            {
                var roles = await _db.UserRoles
                    .Where(ur => ur.UserId == userId && !ur.IsDeleted)
                    .Select(ur => new
                    {
                        ur.Id,
                        ur.UserId,
                        ur.RoleId,
                        role = new { ur.Role.Id, ur.Role.Name, ur.Role.RoleLevel }
                    })
                    .ToListAsync();
                return Ok(roles);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

        [HttpPost("{userId}/roles")]
        public async Task<IActionResult> AssignRole(int userId, [FromBody] ApplicationUserRoleDto dto)
        {
            try
            {
                var existing = await _db.UserRoles
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == dto.RoleId);

                if (existing != null)
                {
                    existing.IsDeleted = false;
                    existing.ModifiedAt = DateTime.Now;
                }
                else
                {
                    _db.UserRoles.Add(new ApplicationUserRole
                    {
                        UserId = userId,
                        RoleId = dto.RoleId,
                        CreatedAt = DateTime.Now,
                        IsDeleted = false
                    });
                }
                await _db.SaveChangesAsync();
                return Ok();
            }
            catch (Exception ex)
            {
                var msg = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(StatusCodes.Status500InternalServerError, msg);
            }
        }

        [HttpDelete("{userId}/roles/{roleId}")]
        public async Task<IActionResult> RemoveRole(int userId, int roleId)
        {
            try
            {
                var entity = await _db.UserRoles
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == roleId);

                if (entity == null) return NotFound();

                entity.IsDeleted = true;
                entity.ModifiedAt = DateTime.Now;
                await _db.SaveChangesAsync();
                return Ok();
            }
            catch (Exception ex)
            {
                var msg = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(StatusCodes.Status500InternalServerError, msg);
            }
        }
    }

}

