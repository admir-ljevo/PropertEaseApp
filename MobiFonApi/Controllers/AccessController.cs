using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Services.AccessManager;
using MobiFon.Shared.Messages;
using MobiFon.ViewModel;
using static MobiFon.Services.AccessManager.AccessManager;

namespace MobiFon.Controllers
{
    [ApiController]
    [Route("[controller]/[action]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        public AccessController (IMapper mapper, IAccessManager accessManager)  /*:base(logger, mapper)*/
        {
            _accessManager = accessManager;
        }

        [HttpPost]
        public async Task<IActionResult> SignIn(AccessSignInViewModel viewModel)
        {
            if (!ModelState.IsValid)
                return BadRequest(Messages.InValidMessage);

            try
            {
                var loginInformation = await _accessManager.SignInAsync(viewModel.UserName, viewModel.Password, viewModel.RememberMe);
                if (loginInformation != null)
                {
                    return Ok(loginInformation);
                }
            }
            catch (Exception exception)
            {
                var e = exception as WrongCredentialsException;

            }
            return BadRequest(Messages.WrongCredentials);
        }
       
    }
}
