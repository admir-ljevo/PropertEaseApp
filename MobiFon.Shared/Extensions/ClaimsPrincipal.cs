using MobiFon.Core.Enumerations;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Security.Claims;
using System.Security.Principal;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Shared.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        public static void AddOrUpdateClaim(this IPrincipal principal, string type, string value)
        {
            if (!(principal.Identity is ClaimsIdentity claimsIdentity))
                return;

            AddOrUpdateClaim(claimsIdentity, type, value);
        }

        public static void AddOrUpdateClaim(this ClaimsIdentity claimsIdentity, string type, string value)
        {
            claimsIdentity.RemoveClaim(type);

            claimsIdentity.AddClaim(new Claim(type, value));
        }

        public static void RemoveClaim(this IPrincipal principal, string type)
        {
            if (!(principal.Identity is ClaimsIdentity claimsIdentity))
                return;

            RemoveClaim(claimsIdentity, type);
        }

        public static void RemoveClaim(this ClaimsIdentity claimsIdentity, string type)
        {
            var claim = claimsIdentity.FindFirst(type);
            if (claim != null)
                claimsIdentity.RemoveClaim(claim);
        }

        public static void RemoveAllClaims(this IPrincipal principal, string type)
        {
            if (!(principal.Identity is ClaimsIdentity claimsIdentity))
                return;

            var claims = claimsIdentity.FindAll(type).ToList();
            foreach (var item in claims)
                claimsIdentity.RemoveClaim(item);
        }

        public static void RemoveAllClaims(this ClaimsIdentity claimsIdentity, string type)
        {
            var claims = claimsIdentity.FindAll(type).ToList();
            foreach (var item in claims)
                claimsIdentity.RemoveClaim(item);
        }

        public static string GetClaimValue(this IPrincipal principal, string type)
        {
            if (!(principal.Identity is ClaimsIdentity claimsIdentity))
                return null;

            var claim = claimsIdentity.Claims.FirstOrDefault(c => c.Type == type);
            return claim?.Value;
        }

        public static bool IsInRole(this IPrincipal principal, Role role)
        {
            return principal.IsInRole(((int)role).ToString());
        }

        public static bool IsInRoles(this IPrincipal principal, params Role[] roles)
        {
            return roles.Any(x => principal.IsInRole(x.TryCast<int>().ToString()));
        }

        public static bool IsLoggedIn(this ClaimsPrincipal principal)
        {
            return principal.Identity != null && principal.Identity.IsAuthenticated;
        }
    }
}
