using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Shared.Extensions
{

    public static class StringExtensions
    {
        public static string ToTsQuery(this string searchTerm) => string.IsNullOrEmpty(searchTerm) ? null : searchTerm.Replace(" ", " & ");

        public static bool IsSet(this string source)
        {
            return !string.IsNullOrWhiteSpace(source);
        }

        public static string Remove(this string source, string value)
        {
            return source.Replace(value, string.Empty);
        }

        public static string FormatString(this string format, params object[] args)
        {
            return string.Format(format, args);
        }

        public static string JoinString<T>(this IEnumerable<T> source, string separator)
        {
            return string.Join(separator, source);
        }

        public static List<int> JoinInt(this string source)
        {
            return source?.Split(',').Select(x => int.TryParse(x, out var value) ? value : 0).ToList();
        }

        public static string RemoveControllerNameSuffix(this string source)
        {
            return source.Remove("Controller");
        }

        public static bool Contains(this string source, string item, StringComparison stringComparison)
        {
            return source != null && item != null && source.IndexOf(item, stringComparison) >= 0;
        }

        public static int ToInt(this string value)
        {
            return int.Parse(value);
        }

        public static bool IsSame(this string firstString, string secondString)
        {
            return string.Equals(firstString, secondString, StringComparison.OrdinalIgnoreCase);
        }
    }
}
