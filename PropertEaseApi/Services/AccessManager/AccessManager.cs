using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Shared.Constants;
using PropertEase.Shared.Extensions;
using PropertEase.Shared.Models;
using PropertEase.Shared.Services.Crypto;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace PropertEase.Services.AccessManager
{
    public class AccessManager : IAccessManager
    {

        private readonly UnitOfWork _unitOfWork;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ICrypto _cryptoService;
        private readonly IApplicationUsersService _applicationUsersService;
        private readonly IConfiguration _configuration;
        private readonly JWTConfig _jwtConfig;

        public AccessManager(ICrypto cryptoService,
                            IUnitOfWork unitOfWork,
                            IApplicationUsersService applicationUsersService,
                            UserManager<ApplicationUser> userManager,
                            IOptions<JWTConfig> jwtConfig,
                            IConfiguration configuration)
        {
            _cryptoService = cryptoService;
            _applicationUsersService = applicationUsersService;
            _unitOfWork = (UnitOfWork)unitOfWork;
            _userManager = userManager;
            _jwtConfig = jwtConfig.Value;
            _configuration = configuration;

        }

        public async Task<IdentityResult> ChangePassword(string currentPassword, string newPassword, string userId)
        {
            return await _userManager.ChangePasswordAsync(await _userManager.FindByIdAsync(userId), currentPassword, newPassword);
        }

        public Task ResetPassword(string email)
        {
            throw new NotImplementedException();
        }

        public async Task<IdentityResult> AdminResetPassword(string userId, string newPassword)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return IdentityResult.Failed(new IdentityError { Description = $"User {userId} not found." });

            var removeResult = await _userManager.RemovePasswordAsync(user);
            if (!removeResult.Succeeded)
                return removeResult;

            return await _userManager.AddPasswordAsync(user, newPassword);
        }

        private string GenerateToken(ApplicationUserDto user)
        {

            var claims = CreateClaims(user);

            var tokenKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration.GetSection(ConfigurationValues.TokenKey).Value));
            var signInCreds = new SigningCredentials(tokenKey, SecurityAlgorithms.HmacSha512Signature);
            var token = new JwtSecurityToken(claims: claims, expires: DateTime.Now.AddMinutes(int.Parse(_configuration.GetSection(ConfigurationValues.TokenValidityInMinutes).Value)), signingCredentials: signInCreds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private IEnumerable<Claim> CreateClaims(ApplicationUserDto user)
        {
            var identity = new ClaimsIdentity(CookieAuthenticationDefaults.AuthenticationScheme);

            identity.AddClaim(new Claim(nameof(user.Id), user.Id.ToString()));
            identity.AddClaim(new Claim(nameof(user.Email), user.Email ?? ""));

            if (user.Person != null)
            {
                identity.AddClaim(new Claim(nameof(user.Person.FirstName), user.Person.FirstName ?? ""));
                identity.AddClaim(new Claim(nameof(user.Person.LastName), user.Person.LastName ?? ""));

                if (user.Person.ProfilePhoto.IsSet())
                    identity.AddClaim(new Claim(CustomClaimTypes.ProfilePhoto, CustomClaimTypes.ProfilePhoto));

                if (user.Person.ProfilePhotoThumbnail.IsSet())
                    identity.AddClaim(new Claim(CustomClaimTypes.ProfilePhoto, user.Person.ProfilePhotoThumbnail));
            }

            if (user.UserRoles != null)
                foreach (var item in user.UserRoles)
                    identity.AddClaim(new Claim(ClaimTypes.Role, item.RoleId.ToString()));

            return identity.Claims;
        }


        public async Task<LoginInformation> SignInAsync(string username, string password, bool rememberMe = false)
        {
            // Get the actual tracked entity for password verification
            var actualUser = await _userManager.FindByNameAsync(username)
                          ?? await _userManager.FindByEmailAsync(username);

            if (actualUser == null || !actualUser.Active)
                throw new UserNotFoundException();

            if (!await _userManager.CheckPasswordAsync(actualUser, password))
                throw new WrongCredentialsException(null);

            // Get the full DTO (with Person, roles, etc.) for the response
            var user = await _applicationUsersService.FindByUserNameOrEmailAsync(username);
            if (user == null)
                throw new UserNotFoundException();

            var firstUserRole = user.UserRoles?.FirstOrDefault();
            var roleId = firstUserRole?.RoleId;
            var roleName = firstUserRole?.Role?.Name
                        ?? (user.IsAdministrator ? "Administrator"
                          : user.IsEmployee || user.IsCompanyOwner ? "Renter"
                          : user.IsClient ? "Client"
                          : null);

            var isRenter = user.UserRoles?.Any(r => r.Role?.Name == "Renter") == true
                        || user.IsCompanyOwner
                        || user.IsEmployee;

            return new LoginInformation
            {
                User = user,
                Token = GenerateToken(user),
                UserId = user.Id,
                Role = roleName,
                RoleId = roleId,
                IsRenter = isRenter
            };
        }



        public class UserNotFoundException : Exception
        {
            public UserNotFoundException(string message = null) : base(message) { }
        }

        public class WrongCredentialsException : Exception
        {
            public ApplicationUserDto User { get; set; }

            public WrongCredentialsException(ApplicationUserDto user, string message = null) : base(message)
            {
                User = user;
            }
        }

    }
}
