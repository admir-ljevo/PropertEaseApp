using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using PropertEase.Worker.Messages;
using PropertEase.Worker.Services;
using ReservationNotificationMessage = PropertEase.Worker.Messages.ReservationNotificationMessage;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace PropertEase.Worker.Workers;

public class ReservationWorker : BackgroundService
{
    private readonly IConfiguration _config;
    private readonly ILogger<ReservationWorker> _logger;
    private readonly IEmailService _emailService;
    private readonly INotificationWriter _notificationWriter;
    private IConnection? _connection;
    private IModel? _channel;

    private const string ConfirmedQueue = "reservation.confirmed";
    private const string CancelledQueue = "reservation.cancelled";
    private const string NotificationQueue = "reservation.notification";
    private const string Exchange = "propertease.exchange";

    public ReservationWorker(IConfiguration config, ILogger<ReservationWorker> logger,
        IEmailService emailService, INotificationWriter notificationWriter)
    {
        _config = config;
        _logger = logger;
        _emailService = emailService;
        _notificationWriter = notificationWriter;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = _config["RabbitMQ:Host"] ?? "localhost",
            Port = int.Parse(_config["RabbitMQ:Port"] ?? "5672"),
            UserName = _config["RabbitMQ:Username"] ?? "guest",
            Password = _config["RabbitMQ:Password"] ?? "guest",
            DispatchConsumersAsync = true
        };

        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();

        _channel.ExchangeDeclare(Exchange, ExchangeType.Topic, durable: true);

        _channel.QueueDeclare(ConfirmedQueue, durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(CancelledQueue, durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(NotificationQueue, durable: true, exclusive: false, autoDelete: false);

        _channel.QueueBind(ConfirmedQueue, Exchange, "reservation.confirmed");
        _channel.QueueBind(CancelledQueue, Exchange, "reservation.cancelled");
        _channel.QueueBind(NotificationQueue, Exchange, "reservation.notification");

        _channel.BasicQos(0, 1, false);

        _logger.LogInformation("ReservationWorker connected to RabbitMQ, listening on queues...");

        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        stoppingToken.ThrowIfCancellationRequested();

        var confirmedConsumer = new AsyncEventingBasicConsumer(_channel);
        confirmedConsumer.Received += OnReservationConfirmed;
        _channel.BasicConsume(ConfirmedQueue, autoAck: false, confirmedConsumer);

        var cancelledConsumer = new AsyncEventingBasicConsumer(_channel);
        cancelledConsumer.Received += OnReservationCancelled;
        _channel.BasicConsume(CancelledQueue, autoAck: false, cancelledConsumer);

        var notificationConsumer = new AsyncEventingBasicConsumer(_channel);
        notificationConsumer.Received += OnReservationNotification;
        _channel.BasicConsume(NotificationQueue, autoAck: false, notificationConsumer);

        while (!stoppingToken.IsCancellationRequested)
            await Task.Delay(1000, stoppingToken);
    }

    private async Task OnReservationConfirmed(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        try
        {
            var message = JsonConvert.DeserializeObject<ReservationConfirmedMessage>(body);
            if (message is null) return;

            _logger.LogInformation("Processing confirmed reservation {ReservationNumber}", message.ReservationNumber);

            await _emailService.SendReservationConfirmationAsync(
                message.ClientEmail,
                message.ClientFullName,
                message.PropertyName,
                message.ReservationNumber,
                message.CheckIn,
                message.CheckOut,
                message.TotalPrice);

            if (!string.IsNullOrEmpty(message.RenterEmail))
            {
                await Task.Delay(2000);
                await _emailService.SendRenterNewReservationAsync(
                    message.RenterEmail,
                    message.RenterFullName,
                    message.ClientFullName,
                    message.PropertyName,
                    message.ReservationNumber,
                    message.CheckIn,
                    message.CheckOut,
                    message.TotalPrice);
            }

            _channel!.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing confirmed reservation message");
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
        }
    }

    private async Task OnReservationCancelled(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        try
        {
            var message = JsonConvert.DeserializeObject<ReservationCancelledMessage>(body);
            if (message is null) return;

            _logger.LogInformation("Processing cancelled reservation {ReservationNumber}", message.ReservationNumber);

            // Email to client
            await _emailService.SendReservationCancellationAsync(
                message.ClientEmail,
                message.ClientFullName,
                message.PropertyName,
                message.ReservationNumber,
                message.CancellationReason);

            // Email to renter
            if (!string.IsNullOrEmpty(message.RenterEmail))
            {
                await Task.Delay(2000);
                await _emailService.SendRenterReservationCancelledAsync(
                    message.RenterEmail,
                    message.RenterFullName,
                    message.ClientFullName,
                    message.PropertyName,
                    message.ReservationNumber,
                    message.CheckIn,
                    message.CheckOut,
                    message.TotalPrice,
                    message.CancellationReason);
            }

            // In-app notification for client
            if (message.ClientUserId > 0)
            {
                await _notificationWriter.WriteAsync(
                    message.ClientUserId,
                    message.ReservationId,
                    $"Vaša rezervacija za nekretninu \"{message.PropertyName}\" je otkazana.",
                    message.ReservationNumber,
                    message.PropertyName,
                    message.PropertyPhotoUrl);
            }

            // In-app notification for renter
            if (message.RenterUserId.HasValue && message.RenterUserId.Value > 0)
            {
                await _notificationWriter.WriteAsync(
                    message.RenterUserId.Value,
                    message.ReservationId,
                    $"Rezervacija \"{message.ReservationNumber}\" za nekretninu \"{message.PropertyName}\" je otkazana.",
                    message.ReservationNumber,
                    message.PropertyName,
                    message.PropertyPhotoUrl);
            }

            _channel!.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing cancelled reservation message");
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
        }
    }

    private async Task OnReservationNotification(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        try
        {
            var message = JsonConvert.DeserializeObject<ReservationNotificationMessage>(body);
            if (message is null) return;

            _logger.LogInformation("Creating notification for user {UserId}, reservation {ReservationNumber}",
                message.UserId, message.ReservationNumber);

            await _notificationWriter.WriteAsync(
                message.UserId,
                message.ReservationId,
                message.Message,
                message.ReservationNumber,
                message.PropertyName,
                message.PropertyPhotoUrl);

            _channel!.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing reservation notification message");
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
        }
    }

    public override void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
        base.Dispose();
    }
}
