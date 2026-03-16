using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Photo;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Core.Dto.ApplicationUser;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
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
        public async Task<IActionResult> Get()
        {
            return Ok(await ApplicationUsersService.GetClients());
        }

        [HttpGet("{id}")]
        public virtual async Task<IActionResult> Get(int id)
        {
            return Ok(await ApplicationUsersService.GetByIdAsync(id));
        }
        [HttpPut("Edit/{id}")]
        public async Task<IActionResult> Put(int id, [FromForm] ClientUpdateDto entity)
        {
            var file = entity.File;
            byte[] imageBytes = null;

            if (file != null)
            {
                entity.ProfilePhoto = await _fileManager.UploadFile(file);
                entity.ProfilePhotoBytes = await _fileManager.UploadFileAsBase64String(file);
            

            }

            return Ok(await ApplicationUsersService.EditClient(entity));
        }
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
