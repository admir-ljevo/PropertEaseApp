using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.ApplicationUsersService;

namespace MobiFon.Controllers
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

        [HttpPost("Add")]
        public async Task<IActionResult> Add(ClientInsertDto entity)
        {
            var newClient = await ApplicationUsersService.AddClientAsync(entity);
            return Ok(newClient);
        }
    }
}
