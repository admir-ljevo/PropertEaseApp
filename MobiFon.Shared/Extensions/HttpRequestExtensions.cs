using Microsoft.AspNetCore.Http;
using Newtonsoft.Json;

namespace MobiFon.Shared.Extensions
{
    public static class HttpRequestExtensions
    {
        public static T GetObject<T>(this HttpRequest request, string key)
        {
            return request.Cookies[key] == null ? default : JsonConvert.DeserializeObject<T>(request.Cookies[key]);
        }

        public static void SetObject(this HttpResponse response, string key, object value, int? expireTime = null)
        {
            if (response == null)
                return;

            if (value == null)
            {
                response.Cookies.Delete(key);
                return;
            }

            var json = JsonConvert.SerializeObject(value);
            var options = new CookieOptions
            {
                Expires = expireTime.HasValue ? DateTime.Now.AddMinutes(expireTime.GetValueOrDefault()) : DateTime.Now.AddDays(7)
            };

            response.RemoveObject(key);
            response.Cookies.Append(key, json, options);
        }

        public static void RemoveObject(this HttpResponse response, string key)
        {
            if (response == null)
                return;

            response.Cookies.Delete(key);
        }
    }
}
