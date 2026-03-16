using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Services.Services.PropertyReservationService;

namespace PropertEase.Services.Services.PropertyReservationBackgroundService
{
    public class PropertyReservationBackgroundService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<PropertyReservationBackgroundService> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromSeconds(180);

        public PropertyReservationBackgroundService(
            IServiceScopeFactory scopeFactory,
            ILogger<PropertyReservationBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var propertyReservationService =
                        scope.ServiceProvider.GetRequiredService<IPropertyReservationService>();

                    var deactivated = await propertyReservationService.DeactivateExpiredAsync();
                    if (deactivated > 0)
                        _logger.LogInformation("Deactivated {Count} expired reservations.", deactivated);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "PropertyReservationBackgroundService error");
                }

                await Task.Delay(_interval, stoppingToken);
            }
        }
    }
}