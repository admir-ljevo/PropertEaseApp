using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.ApplicationUsersService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ApplicationUserController : ControllerBase
    {
        private readonly IApplicationUsersService ApplicationUsersService;
        private readonly IFileManager _fileManager;

        public ApplicationUserController(IFileManager fileManager, IApplicationUsersService applicationUsersService)
        {
            _fileManager = fileManager;
            ApplicationUsersService = applicationUsersService;
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
    }

}

