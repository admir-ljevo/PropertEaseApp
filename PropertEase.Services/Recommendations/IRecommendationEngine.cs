namespace PropertEase.Services.Recommendations;

public interface IRecommendationEngine
{
    /// <summary>
    /// Returns IDs of properties recommended for a given user based on
    /// association rules derived from reservation history.
    /// </summary>
    Task<IReadOnlyList<int>> GetRecommendationsAsync(int userId);

    /// <summary>
    /// Returns IDs of properties most frequently co-reserved by clients who
    /// also reserved the specified property (item-based association rules).
    /// </summary>
    Task<IReadOnlyList<int>> GetRecommendationsByPropertyAsync(int propertyId);
}
