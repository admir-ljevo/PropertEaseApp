namespace PropertEase.Controllers
{
    internal static class Paging
    {
        internal static int Clamp(int pageSize, int max = 100) => Math.Min(pageSize, max);
    }
}
