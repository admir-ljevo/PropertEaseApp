using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Services.Services.PropertyReservationService;

namespace MobiFon.Services.Services.PropertyReservationBackgroundService
{
    public class PropertyReservationBackgroundService : IHostedService
    {

        private readonly IServiceProvider serviceProvider;
        private readonly ILogger<PropertyReservationBackgroundService> logger;
        private Timer timer;
        private readonly TimeSpan interval = TimeSpan.FromSeconds(180);

        public PropertyReservationBackgroundService(IServiceProvider serviceProvider, ILogger<PropertyReservationBackgroundService> logger)
        {
            this.serviceProvider = serviceProvider;
            this.logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            timer = new Timer(DoWork, null, TimeSpan.Zero, interval);

            return Task.CompletedTask;
        }

        private async void DoWork(object? state)
        {
            logger.LogInformation("runjetluk");
            using (var scope = serviceProvider.CreateScope())
            {
                var propertyReservationService = scope.ServiceProvider.GetRequiredService<IPropertyReservationService>();
                //var propertyService = scope.ServiceProvider.GetRequiredService<IPropertyService>();
                List<PropertyReservationDto> reservations = await propertyReservationService.GetAllAsync();
                foreach (var reservation in reservations.Where(r => r.DateOfOccupancyEnd <= DateTime.Now && r.IsActive))
                {
                    logger.LogInformation($"Updating reservation: {reservation.Id}");
                    reservation.IsActive = false;
                    propertyReservationService.Update(reservation);
                }
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }
    }
}
