
namespace PropertEase.Core.Filters
{
    public class UserFilter
    {
        public string? SearchField {get;set;}
        public string? Role { get; set; }
        public int? CityId { get; set; }

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
