using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Shared.Extensions
{
    public static class CollectionExtensions
    {
        public static bool IsEmpty<T>(this IEnumerable<T> source, Func<T, bool> predicate = null)
        {
            return source == null || (predicate != null ? !source.Any(predicate) : !source.Any());
        }

        public static IEnumerable<IGrouping<int, TSource>> GroupBy<TSource>(this IList<TSource> source, int itemsPerGroup)
        {
            return source.Zip(Enumerable.Range(0, source.Count()),
                    (s, r) => new { Group = r / itemsPerGroup, Item = s })
                .GroupBy(i => i.Group, g => g.Item)
                .ToList();
        }

    }
}
