namespace MobiFon.Services.Recommendations;

public interface IRecommendationEngine
{
    /// <summary>
    /// Returns IDs of properties recommended for a given user based on
    /// association rules derived from reservation history.
    /// </summary>
    Task<IReadOnlyList<int>> GetRecommendationsAsync(int userId);
}
