namespace PropertEase.Services.Recommendations;

public class RecommendationConfig
{
    public double MinSupport { get; set; } = 0.05;
    public double MinConfidence { get; set; } = 0.3;
    public int MaxRecommendations { get; set; } = 5;
}
