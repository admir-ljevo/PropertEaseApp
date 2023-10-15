using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Services.Services.ApplicationRolesService;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RoleController : ControllerBase
    {
        public IApplicationRolesService applicationRolesService;
        public RoleController(IApplicationRolesService applicationRolesService)
        {
            this.applicationRolesService = applicationRolesService;
        }
        [HttpGet]
        public async Task<IActionResult> GetAllAsync() {
            try
            {
                var roles = await applicationRolesService.GetAllAsync();
                return Ok(roles);
            }
            catch (Exception ex)
            {

                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }

    }
}
