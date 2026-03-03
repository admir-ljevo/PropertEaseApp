namespace MobiFon.Services.Recommendations;

public class RecommendationConfig
{
    /// <summary>Minimum support threshold (0-1). Items appearing in fewer transactions are ignored.</summary>
    public double MinSupport { get; set; } = 0.05;

    /// <summary>Minimum confidence threshold (0-1). Rules with lower confidence are discarded.</summary>
    public double MinConfidence { get; set; } = 0.3;

    /// <summary>Maximum number of recommendations to return per request.</summary>
    public int MaxRecommendations { get; set; } = 5;
}
