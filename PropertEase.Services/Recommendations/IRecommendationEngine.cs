namespace PropertEase.Services.Recommendations;

public interface IRecommendationEngine
{
    Task<IReadOnlyList<int>> GetRecommendationsAsync(int userId);

    Task<IReadOnlyList<RecommendationItem>> GetRecommendationsByPropertyAsync(int propertyId);
}
