using PropertEase.Core.Dto.City;

namespace PropertEase.Core.Dto.Property
{
    public class PropertyRecommendationDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int CityId { get; set; }
        public CityDto City { get; set; }
        public int ApplicationUserId { get; set; }
        public float? MonthlyPrice { get; set; }
        public float? DailyPrice { get; set; }
        public bool IsMonthly { get; set; }
        public bool IsDaily { get; set; }
        public bool IsAvailable { get; set; }
        public string FirstPhotoUrl { get; set; }
    }
}
