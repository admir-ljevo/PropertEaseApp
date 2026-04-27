namespace PropertEase.Services.Recommendations;

public interface IRecommendationEngine
{
    /// <summary>
    /// Returns IDs of properties recommended for a given user based on
    /// association rules derived from reservation history.
    /// </summary>
    Task<IReadOnlyList<int>> GetRecommendationsAsync(int userId);

    /// <summary>
    /// Returns properties most frequently co-reserved by clients who also reserved
    /// the specified property, together with the association-rule confidence score.
    /// </summary>
    Task<IReadOnlyList<RecommendationItem>> GetRecommendationsByPropertyAsync(int propertyId);
}
