using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Core.Filters;
using PropertEase.Shared.Constants;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class EmployeeController : ControllerBase
    {
        private readonly IFileManager _fileManager;
        private readonly IApplicationUsersService ApplicationUsersService;
        public EmployeeController(IFileManager fileManager, IApplicationUsersService applicationUsersService)
        {
            _fileManager = fileManager;
            ApplicationUsersService = applicationUsersService;

        }

        [Authorize(Roles = AppRoles.Admin)]
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

        [Authorize(Roles = AppRoles.Admin)]
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


        [HttpGet("GetRenters")]
        public async Task<IActionResult> GetRenters([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            pageSize = Paging.Clamp(pageSize);
            var result = await ApplicationUsersService.GetFiltered(
                new UserFilter { Page = page, PageSize = pageSize, Role = "Renter" });
            return Ok(result.Items);
        }

        [HttpGet("{id:int}")]
        public virtual async Task<IActionResult> Get(int id)
        {
            return Ok(await ApplicationUsersService.GetByIdAsync(id));
        }
    }

}
