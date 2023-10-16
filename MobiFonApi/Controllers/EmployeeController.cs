using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.ApplicationUsersService;
using PropertEase.Core.Dto.ApplicationUser;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmployeeController : ControllerBase
    {
        private readonly IFileManager _fileManager;
        private readonly IApplicationUsersService ApplicationUsersService;
        public EmployeeController(IFileManager fileManager, IApplicationUsersService applicationUsersService)
        {
            _fileManager = fileManager;
            ApplicationUsersService = applicationUsersService;

        }

        [HttpPost("Add")]
        public async Task<IActionResult> Add([FromForm] EmployeeInsertDto entity)
        {
            var file = entity.File;
            if (file != null)
            {
                entity.ProfilePhoto = await _fileManager.UploadFile(file);
            }
            return Ok(await ApplicationUsersService.AddEmployeeAsync(entity));
        }

        [HttpPut("Edit/{id}")]
        public async Task<IActionResult> Put(int id, [FromForm] EmployeeUpdateDto entity)
        {
            var file = entity.File;
            if (file != null)
            {
                entity.ProfilePhoto = await _fileManager.UploadFile(file);
            }
            return Ok(await ApplicationUsersService.EditEmployee(entity));
        }


        [HttpGet("Get")]
        public async Task<IActionResult> Get()
        {
            return Ok(await ApplicationUsersService.GetEmployees());
        }

        [HttpGet("{id}")]
        public virtual async Task<IActionResult> Get(int id)
        {
            return Ok(await ApplicationUsersService.GetByIdAsync(id));
        }
    }

}
