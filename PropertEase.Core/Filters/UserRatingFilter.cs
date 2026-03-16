namespace PropertEase.Core.Filters
{
    public class UserRatingFilter
    {
        public int? RenterId { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
