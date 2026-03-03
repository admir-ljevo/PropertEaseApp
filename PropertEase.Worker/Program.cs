using PropertEase.Worker.Services;
using PropertEase.Worker.Workers;

IHost host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration((hostContext, config) =>
    {
        config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
        config.AddJsonFile($"appsettings.{hostContext.HostingEnvironment.EnvironmentName}.json", optional: true);
        config.AddEnvironmentVariables();
    })
    .ConfigureServices((context, services) =>
    {
        services.AddScoped<IEmailService, EmailService>();
        services.AddHostedService<ReservationWorker>();
    })
    .Build();

await host.RunAsync();
