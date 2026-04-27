using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.AccessManager;
using PropertEase.Shared.Constants;
using PropertEase.Shared.Messages;
using PropertEase.Shared.Services.LoggedUserData;
using PropertEase.Shared.Services.TokenBlacklist;
using PropertEase.ViewModel;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using static PropertEase.Services.AccessManager.AccessManager;

namespace PropertEase.Controllers
{
    [ApiController]
    [Route("api/[controller]/[action]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        private readonly ILoggedUserData _loggedUserData;
        private readonly ITokenBlacklistService _tokenBlacklist;

        public AccessController(IAccessManager accessManager, ILoggedUserData loggedUserData, ITokenBlacklistService tokenBlacklist)
        {
            _accessManager = accessManager;
            _loggedUserData = loggedUserData;
            _tokenBlacklist = tokenBlacklist;
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
                    return Ok(loginInformation);
            }
            catch (WrongCredentialsException)
            {
            }
            return BadRequest(Messages.WrongCredentials);
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Extract userId from JWT — never trust client-supplied userId for own-password operations
            var userIdClaim = User.FindFirstValue("Id")
                ?? throw new UnauthorizedAccessException("User ID not found in token.");

            var result = await _accessManager.ChangePassword(model.CurrentPassword, model.NewPassword, userIdClaim);

            if (result.Succeeded)
                return Ok("Password changed successfully.");

            return BadRequest(result.Errors);
        }

        // Public — sends a 6-digit OTP to the user email. Always returns 200 for seucrity
    
        [HttpPost]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            await _accessManager.ForgotPasswordAsync(model.Email);
            return Ok(new { message = "Ako je email registrovan, poslan je kod za resetovanje lozinke." });
        }

       
        [HttpPost]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _accessManager.ResetPasswordAsync(model.Email, model.Otp, model.NewPassword);

            if (result.Succeeded)
                return Ok(new { message = "Lozinka je uspješno promijenjena." });

            return BadRequest(result.Errors);
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost]
        public async Task<IActionResult> AdminResetPassword([FromBody] AdminResetPasswordModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _accessManager.AdminResetPassword(model.UserId, model.NewPassword);

            if (result.Succeeded)
                return Ok("Password reset successfully.");

            return BadRequest(result.Errors);
        }

        [Authorize]
        [HttpPost]
        public IActionResult Logout()
        {
            var authHeader = Request.Headers["Authorization"].ToString();
            if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                var token = authHeader["Bearer ".Length..].Trim();
                var handler = new JwtSecurityTokenHandler();
                if (handler.CanReadToken(token))
                {
                    var jwt = handler.ReadJwtToken(token);
                    _tokenBlacklist.Revoke(token, jwt.ValidTo);
                }
            }
            return Ok(new { message = "Logged out successfully." });
        }
    }
}
