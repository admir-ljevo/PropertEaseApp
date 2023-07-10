using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Shared.Extensions
{
    public static class ObjectExtensions
    {
        public static string ToQueryString(this object source, object additionalParameters = null)
        {
            var urlBuilder = new StringBuilder("?");

            ExtractData(source, urlBuilder);

            if (additionalParameters != null)
                ExtractData(additionalParameters, urlBuilder);

            if (urlBuilder.Length > 1)
                urlBuilder.Remove(urlBuilder.Length - 1, 1);

            return urlBuilder.ToString();
        }

        private static void ExtractData(object source, StringBuilder urlBuilder)
        {
            var properties = source.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var property in properties)
                urlBuilder.AppendFormat("{0}={1}&", property.Name, property.GetValue(source, null));
        }

        public static object ToRouteValuesObject(this object source, object additionalParameters = null)
        {
            var dictionary = new Dictionary<string, object>();

            ExtractRouteValuesData(source, dictionary);
            if (additionalParameters != null)
                ExtractRouteValuesData(additionalParameters, dictionary);

            var expandoObj = new ExpandoObject();
            var expandoObjCollection = (ICollection<KeyValuePair<String, Object>>)expandoObj;

            foreach (var keyValuePair in dictionary)
            {
                expandoObjCollection.Add(keyValuePair);
            }
            dynamic eoDynamic = expandoObj;
            return eoDynamic;
        }
        private static void ExtractRouteValuesData(object source, Dictionary<string, object> dictionary)
        {
            var properties = source?.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            foreach (var property in properties)
                dictionary.Add(property.Name, property.GetValue(source, null));
        }
        public static T TryCast<T>(this object obj)
        {
            try
            {
                return (T)obj;
            }
            catch
            {
                return default;
            }
        }
    }
}
