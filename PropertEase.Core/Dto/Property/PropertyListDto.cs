using PropertEase.Core.Dto.City;
using PropertEase.Core.Dto.PropertyType;

namespace PropertEase.Core.Dto.Property;

/// <summary>
/// Lean DTO for property list/search results.
/// Only includes fields displayed on the list card — avoids loading heavy
/// navigation properties (ApplicationUser, Reservations, full Ratings/Photos).
/// </summary>
public class PropertyListDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int CityId { get; set; }
    public CityDto? City { get; set; }
    public int PropertyTypeId { get; set; }
    public PropertyTypeDto? PropertyType { get; set; }
    public int ApplicationUserId { get; set; }
    public int NumberOfRooms { get; set; }
    public int NumberOfBathrooms { get; set; }
    public int SquareMeters { get; set; }
    public float? MonthlyPrice { get; set; }
    public float? DailyPrice { get; set; }
    public bool IsMonthly { get; set; }
    public bool IsDaily { get; set; }
    public bool IsAvailable { get; set; }
    public DateTime? AvailableFrom { get; set; }
    public double AverageRating { get; set; }
    /// <summary>Relative URL of the first property image, e.g. /uploads/images/xyz.jpg</summary>
    public string? FirstPhotoUrl { get; set; }
    public string? Description {  get; set; }   

}
