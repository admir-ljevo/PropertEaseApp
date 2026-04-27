using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Photo;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Core.Filters;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ClientsController : ControllerBase
    {
        private readonly IFileManager _fileManager;
        private readonly IApplicationUsersService ApplicationUsersService;
 
        public ClientsController(IFileManager fileManager, IApplicationUsersService applicationUsersService)
        {
            _fileManager = fileManager;
            ApplicationUsersService = applicationUsersService;

        }


        [HttpGet("Get")]
        public async Task<IActionResult> Get([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            pageSize = Paging.Clamp(pageSize);
            var result = await ApplicationUsersService.GetFiltered(
                new UserFilter { Page = page, PageSize = pageSize, Role = "Client" });
            return Ok(result.Items);
        }

        [HttpGet("{id}")]
        public virtual async Task<IActionResult> Get(int id)
        {
            return Ok(await ApplicationUsersService.GetByIdAsync(id));
        }
        [HttpPut("Edit/{id}")]
        public async Task<IActionResult> Put(int id, [FromForm] ClientUpdateDto entity)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : (int?)null;
            var isAdmin = User.IsInRole(AppRoles.Admin);
            if (!isAdmin && callerId != id)
                return Forbid();

            var file = entity.File;
            if (file != null)
            {
                entity.ProfilePhoto = await _fileManager.UploadFile(file);
                entity.ProfilePhotoBytes = await _fileManager.UploadFileAsBase64String(file);
            }

            return Ok(await ApplicationUsersService.EditClient(entity));
        }
        [AllowAnonymous]
        [HttpPost("Add")]
        public async Task<IActionResult> Add([FromForm]ClientInsertDto entity)
        {
            var file = entity.File;
            byte[] imageBytes = null;

            if (file != null)
            {
                entity.ProfilePhoto = await _fileManager.UploadFile(file);
                imageBytes = await _fileManager.UploadFileAsBase64String(file);


            }
            entity.ProfilePhotoBytes = imageBytes;
            var newClient = await ApplicationUsersService.AddClientAsync(entity);
            return Ok(newClient);
        }
    }
}
