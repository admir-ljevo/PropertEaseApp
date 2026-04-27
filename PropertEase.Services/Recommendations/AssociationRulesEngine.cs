using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Recommendations;

/// <summary>
/// Apriori-based association rules recommendation engine.
/// Finds properties frequently booked together and recommends
/// co-booked properties to users based on their booking history.
/// </summary>
public class AssociationRulesEngine : IRecommendationEngine
{
    private readonly UnitOfWork _uow;
    private readonly RecommendationConfig _config;
    private readonly ILogger<AssociationRulesEngine> _logger;

    public AssociationRulesEngine(
        IUnitOfWork unitOfWork,
        IOptions<RecommendationConfig> config,
        ILogger<AssociationRulesEngine> logger)
    {
        _uow = (UnitOfWork)unitOfWork;
        _config = config.Value;
        _logger = logger;
    }

    public async Task<IReadOnlyList<int>> GetRecommendationsAsync(int userId)
    {
        // 1. Load all reservations (transaction = all properties a single client booked)
        var allReservations = await _uow.PropertyReservationRepository.GetAllAsync();

        // Build transactions: one transaction per client = set of propertyIds they booked
        var transactions = allReservations
            .GroupBy(r => r.ClientId)
            .Select(g => g.Select(r => r.PropertyId).Distinct().ToHashSet())
            .ToList();

        int totalTransactions = transactions.Count;
        if (totalTransactions == 0)
            return Array.Empty<int>();

        // 2. Get the set of properties the current user has already booked
        var userPropertyIds = allReservations
            .Where(r => r.ClientId == userId)
            .Select(r => r.PropertyId)
            .Distinct()
            .ToHashSet();

        if (userPropertyIds.Count == 0)
        {
            // Cold start: return most popular properties
            return allReservations
                .GroupBy(r => r.PropertyId)
                .OrderByDescending(g => g.Count())
                .Take(_config.MaxRecommendations)
                .Select(g => g.Key)
                .ToList();
        }

        // 3. Compute item support (frequency of each property across transactions)
        var itemSupport = new Dictionary<int, double>();
        foreach (var transaction in transactions)
        {
            foreach (var propertyId in transaction)
            {
                itemSupport.TryGetValue(propertyId, out var count);
                itemSupport[propertyId] = count + 1;
            }
        }
        foreach (var key in itemSupport.Keys.ToList())
            itemSupport[key] /= totalTransactions;

        // 4. Compute pairwise co-occurrence for {antecedent → candidate} rules
        //    where antecedent ∈ userPropertyIds and candidate ∉ userPropertyIds
        var candidateScores = new Dictionary<int, double>();

        foreach (var userPropertyId in userPropertyIds)
        {
            double antecedentSupport = itemSupport.GetValueOrDefault(userPropertyId, 0);
            if (antecedentSupport < _config.MinSupport) continue;

            foreach (var transaction in transactions)
            {
                if (!transaction.Contains(userPropertyId)) continue;

                foreach (var candidate in transaction)
                {
                    if (userPropertyIds.Contains(candidate)) continue;

                    double candidateSupport = itemSupport.GetValueOrDefault(candidate, 0);
                    if (candidateSupport < _config.MinSupport) continue;

                    // Confidence = support(A ∪ B) / support(A)
                    // We approximate support(A ∪ B) by co-occurrence count
                    candidateScores.TryGetValue(candidate, out var score);
                    candidateScores[candidate] = score + 1;
                }
            }
        }

        // Normalise to confidence
        var recommendations = candidateScores
            .Select(kv =>
            {
                double antecedentCount = userPropertyIds
                    .Max(uid => transactions.Count(t => t.Contains(uid)));
                double confidence = antecedentCount > 0 ? kv.Value / antecedentCount : 0;
                return new { PropertyId = kv.Key, Confidence = confidence };
            })
            .Where(x => x.Confidence >= _config.MinConfidence)
            .OrderByDescending(x => x.Confidence)
            .Take(_config.MaxRecommendations)
            .Select(x => x.PropertyId)
            .ToList();

        _logger.LogInformation(
            "Generated {Count} recommendations for user {UserId}", recommendations.Count, userId);

        return recommendations;
    }

    public async Task<IReadOnlyList<RecommendationItem>> GetRecommendationsByPropertyAsync(int propertyId)
    {
        // All heavy work is pushed to SQL — no full table load
        var (totalClientCount, propertyClientCount, coOccurrences) =
            await _uow.PropertyReservationRepository.GetRecommendationDataAsync(propertyId);

        if (totalClientCount == 0 || propertyClientCount == 0 || coOccurrences.Count == 0)
            return Array.Empty<RecommendationItem>();

        double antecedentSupport = (double)propertyClientCount / totalClientCount;

        var scored = coOccurrences
            .Select(kv => new
            {
                PropertyId = kv.Key,
                Support = (double)kv.Value / totalClientCount,
                Confidence = (double)kv.Value / propertyClientCount,
            })
            .ToList();

        // Apply thresholds when the antecedent has enough support
        IReadOnlyList<RecommendationItem> recommendations = Array.Empty<RecommendationItem>();
        if (antecedentSupport >= _config.MinSupport)
        {
            recommendations = scored
                .Where(x => x.Support >= _config.MinSupport && x.Confidence >= _config.MinConfidence)
                .OrderByDescending(x => x.Confidence)
                .Take(_config.MaxRecommendations)
                .Select(x => new RecommendationItem(x.PropertyId, x.Confidence))
                .ToList();
        }

        // Fallback: if thresholds filtered everything out, return top by confidence
        if (recommendations.Count == 0)
        {
            recommendations = scored
                .OrderByDescending(x => x.Confidence)
                .Take(_config.MaxRecommendations)
                .Select(x => new RecommendationItem(x.PropertyId, x.Confidence))
                .ToList();
        }

        _logger.LogInformation(
            "Generated {Count} property-based recommendations for property {PropertyId}",
            recommendations.Count, propertyId);

        return recommendations;
    }
}
