using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Api.Messages;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Shared.Constants;
using PropertEase.Shared.Extensions;
using PropertEase.Shared.Models;
using PropertEase.Shared.Services.Crypto;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
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
        private readonly IMemoryCache _cache;
        private readonly IRabbitMQPublisher _publisher;

        private static string OtpCacheKey(string email) => $"pwd_reset:{email.ToLowerInvariant()}";

        private record OtpEntry(string HashedOtp, string Salt, DateTime ExpiresAt);

        private static string HashOtp(string otp, string salt)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(otp + salt));
            return Convert.ToBase64String(bytes);
        }

        public AccessManager(ICrypto cryptoService,
                            IUnitOfWork unitOfWork,
                            IApplicationUsersService applicationUsersService,
                            UserManager<ApplicationUser> userManager,
                            IOptions<JWTConfig> jwtConfig,
                            IConfiguration configuration,
                            IMemoryCache cache,
                            IRabbitMQPublisher publisher)
        {
            _cryptoService = cryptoService;
            _applicationUsersService = applicationUsersService;
            _unitOfWork = (UnitOfWork)unitOfWork;
            _userManager = userManager;
            _jwtConfig = jwtConfig.Value;
            _configuration = configuration;
            _cache = cache;
            _publisher = publisher;
        }

        public async Task<IdentityResult> ChangePassword(string currentPassword, string newPassword, string userId)
        {
            return await _userManager.ChangePasswordAsync(await _userManager.FindByIdAsync(userId), currentPassword, newPassword);
        }

        public async Task ForgotPasswordAsync(string email)
        {
            var user = await _userManager.FindByEmailAsync(email);
            // always return without error, dont review if address exists
            if (user == null || !user.Active) return;

            var otpInt = Math.Abs(BitConverter.ToInt32(RandomNumberGenerator.GetBytes(4), 0)) % 900_000 + 100_000;
            var otp    = otpInt.ToString();
            var salt      = Convert.ToBase64String(RandomNumberGenerator.GetBytes(16));
            var expiresAt = DateTime.UtcNow.AddMinutes(15);
            _cache.Set(OtpCacheKey(email), new OtpEntry(HashOtp(otp, salt), salt, expiresAt), TimeSpan.FromMinutes(15));

            var fullName = user.UserName ?? email;
            var person = _unitOfWork.GetDatabaseContext().Persons
                .FirstOrDefault(p => p.ApplicationUserId == user.Id);
            if (person != null)
                fullName = $"{person.FirstName} {person.LastName}".Trim();

            _publisher.Publish(new PasswordResetMessage
            {
                Email = email,
                FullName = fullName,
                Otp = otp
            }, "password.reset");
        }

        public async Task<IdentityResult> ResetPasswordAsync(string email, string otp, string newPassword)
        {
            if (!_cache.TryGetValue(OtpCacheKey(email), out OtpEntry? entry) || entry == null)
                return IdentityResult.Failed(new IdentityError
                {
                    Code = "InvalidOtp",
                    Description = "Kod je neispravan ili je istekao."
                });

            if (DateTime.UtcNow > entry.ExpiresAt)
            {
                _cache.Remove(OtpCacheKey(email));
                return IdentityResult.Failed(new IdentityError
                {
                    Code = "ExpiredOtp",
                    Description = "Kod je neispravan ili je istekao."
                });
            }

            if (HashOtp(otp, entry.Salt) != entry.HashedOtp)
                return IdentityResult.Failed(new IdentityError
                {
                    Code = "InvalidOtp",
                    Description = "Kod je neispravan ili je istekao."
                });

            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
                return IdentityResult.Failed(new IdentityError
                {
                    Code = "UserNotFound",
                    Description = "Korisnik nije pronađen."
                });

            var removeResult = await _userManager.RemovePasswordAsync(user);
            if (!removeResult.Succeeded) return removeResult;

            var addResult = await _userManager.AddPasswordAsync(user, newPassword);
            if (addResult.Succeeded)
                _cache.Remove(OtpCacheKey(email));

            return addResult;
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
            var signInCreds = new SigningCredentials(tokenKey, SecurityAlgorithms.HmacSha256Signature);
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
                    identity.AddClaim(new Claim(ClaimTypes.Role, item.Role?.Name ?? item.RoleId.ToString()));

            return identity.Claims;
        }


        public async Task<LoginInformation> SignInAsync(string username, string password, bool rememberMe = false)
        {
            var actualUser = await _userManager.FindByNameAsync(username)
                          ?? await _userManager.FindByEmailAsync(username);

            if (actualUser == null || !actualUser.Active)
                throw new UserNotFoundException();

            if (!await _userManager.CheckPasswordAsync(actualUser, password))
                throw new WrongCredentialsException(null);

            var user = await _applicationUsersService.FindByUserNameOrEmailAsync(username);
            if (user == null)
                throw new UserNotFoundException();

            var adminRole = user.UserRoles?.FirstOrDefault(r => r.Role?.Name == "Admin");
            var firstUserRole = adminRole ?? user.UserRoles?.FirstOrDefault();
            var roleId = firstUserRole?.RoleId;
            var roleName = firstUserRole?.Role?.Name;

            var isRenter = user.UserRoles?.Any(r => r.Role?.Name == "Renter") == true;

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
