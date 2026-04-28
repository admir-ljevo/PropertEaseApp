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

    private const string ConfirmedQueue    = "reservation.confirmed";
    private const string CancelledQueue    = "reservation.cancelled";
    private const string NotificationQueue = "reservation.notification";
    private const string PasswordResetQueue = "password.reset";
    private const string PushQueue         = "notification.push";
    private const string Exchange          = "propertease.exchange";

    private const int MaxRetries = 4; // delays: 1s, 2s, 4s, 8s

    public ReservationWorker(IConfiguration config, ILogger<ReservationWorker> logger,
        IEmailService emailService, INotificationWriter notificationWriter)
    {
        _config = config;
        _logger = logger;
        _emailService = emailService;
        _notificationWriter = notificationWriter;
    }

    public override async Task StartAsync(CancellationToken cancellationToken)
    {
        var factory = new ConnectionFactory
        {
            HostName               = _config["RabbitMQ:Host"]     ?? "localhost",
            Port                   = int.Parse(_config["RabbitMQ:Port"] ?? "5672"),
            UserName               = _config["RabbitMQ:Username"] ?? "guest",
            Password               = _config["RabbitMQ:Password"] ?? "guest",
            DispatchConsumersAsync = true
        };

        const int maxAttempts = 12;
        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                _connection = factory.CreateConnection();
                break;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                _logger.LogWarning("RabbitMQ not ready (attempt {Attempt}/{Max}): {Msg}. Retrying in 5s...",
                    attempt, maxAttempts, ex.Message);
                await Task.Delay(5_000, cancellationToken);
            }
        }

        _channel = _connection!.CreateModel();

        _channel.ExchangeDeclare(Exchange, ExchangeType.Topic, durable: true);

        _channel.QueueDeclare(ConfirmedQueue,     durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(CancelledQueue,     durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(NotificationQueue,  durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(PasswordResetQueue, durable: true, exclusive: false, autoDelete: false);
        _channel.QueueDeclare(PushQueue,          durable: true, exclusive: false, autoDelete: false);

        _channel.QueueBind(ConfirmedQueue,     Exchange, "reservation.confirmed");
        _channel.QueueBind(CancelledQueue,     Exchange, "reservation.cancelled");
        _channel.QueueBind(NotificationQueue,  Exchange, "reservation.notification");
        _channel.QueueBind(PasswordResetQueue, Exchange, "password.reset");
        _channel.QueueBind(PushQueue,          Exchange, "notification.push");

        _channel.BasicQos(0, 1, false);

        _logger.LogInformation("ReservationWorker connected to RabbitMQ, listening on queues...");

        await base.StartAsync(cancellationToken);
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

        var passwordResetConsumer = new AsyncEventingBasicConsumer(_channel);
        passwordResetConsumer.Received += OnPasswordReset;
        _channel.BasicConsume(PasswordResetQueue, autoAck: false, passwordResetConsumer);

        while (!stoppingToken.IsCancellationRequested)
            await Task.Delay(1000, stoppingToken);
    }

    // Retries the handler up to MaxRetries times with exponential backoff (1s, 2s, 4s, 8s).
    // Acks on success; nacks without requeue after all retries are exhausted.
    private async Task ExecuteWithRetryAsync(
        BasicDeliverEventArgs ea,
        Func<Task> handler,
        string handlerName,
        CancellationToken ct = default)
    {
        for (int attempt = 1; ; attempt++)
        {
            try
            {
                await handler();
                _channel!.BasicAck(ea.DeliveryTag, false);
                return;
            }
            catch (Exception ex) when (attempt <= MaxRetries && !ct.IsCancellationRequested)
            {
                var delaySec = Math.Pow(2, attempt - 1); // 1, 2, 4, 8
                _logger.LogWarning(ex,
                    "{Handler} failed (attempt {Attempt}/{MaxRetries}). Retrying in {Delay}s.",
                    handlerName, attempt, MaxRetries, delaySec);
                await Task.Delay(TimeSpan.FromSeconds(delaySec), ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "{Handler} failed after {MaxRetries} retries. Discarding message.",
                    handlerName, MaxRetries);
                _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
                return;
            }
        }
    }

    private async Task OnReservationConfirmed(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        var message = JsonConvert.DeserializeObject<ReservationConfirmedMessage>(body);
        if (message is null)
        {
            _logger.LogWarning("Received null/unparseable message on {Queue}. Discarding.", ConfirmedQueue);
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
            return;
        }

        await ExecuteWithRetryAsync(ea, async () =>
        {
            _logger.LogInformation("Processing confirmed reservation {ReservationNumber}", message.ReservationNumber);

            if (!string.IsNullOrEmpty(message.ClientEmail))
            {
                await _emailService.SendReservationConfirmationAsync(
                    message.ClientEmail, message.ClientFullName, message.PropertyName,
                    message.ReservationNumber, message.CheckIn, message.CheckOut,
                    message.TotalPrice, message.ActorFullName);
            }

            if (!string.IsNullOrEmpty(message.RenterEmail))
            {
                await Task.Delay(2000);
                await _emailService.SendRenterNewReservationAsync(
                    message.RenterEmail, message.RenterFullName, message.ClientFullName,
                    message.PropertyName, message.ReservationNumber,
                    message.CheckIn, message.CheckOut, message.TotalPrice);
            }

            if (message.ClientUserId > 0)
            {
                var notificationText = string.IsNullOrEmpty(message.ActorFullName)
                    ? $"Vaša rezervacija za nekretninu \"{message.PropertyName}\" je potvrđena. Otvorite aplikaciju da izvršite plaćanje."
                    : $"Vaša rezervacija za nekretninu \"{message.PropertyName}\" je potvrđena od strane {message.ActorFullName}. Otvorite aplikaciju da izvršite plaćanje.";

                var notifId = await _notificationWriter.WriteAsync(
                    message.ClientUserId, message.ReservationId,
                    title: "Rezervacija potvrđena",
                    notificationText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);

                PublishPush(notifId, message.ClientUserId, message.ReservationId,
                    "Rezervacija potvrđena", notificationText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);
            }
        }, nameof(OnReservationConfirmed));
    }

    private async Task OnReservationCancelled(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        var message = JsonConvert.DeserializeObject<ReservationCancelledMessage>(body);
        if (message is null)
        {
            _logger.LogWarning("Received null/unparseable message on {Queue}. Discarding.", CancelledQueue);
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
            return;
        }

        await ExecuteWithRetryAsync(ea, async () =>
        {
            _logger.LogInformation("Processing cancelled reservation {ReservationNumber}", message.ReservationNumber);

            await _emailService.SendReservationCancellationAsync(
                message.ClientEmail, message.ClientFullName, message.PropertyName,
                message.ReservationNumber, message.CancellationReason, message.ActorFullName);

            if (!string.IsNullOrEmpty(message.RenterEmail))
            {
                await Task.Delay(2000);
                await _emailService.SendRenterReservationCancelledAsync(
                    message.RenterEmail, message.RenterFullName, message.ClientFullName,
                    message.PropertyName, message.ReservationNumber,
                    message.CheckIn, message.CheckOut, message.TotalPrice, message.CancellationReason);
            }

            if (message.ClientUserId > 0)
            {
                var clientText = string.IsNullOrEmpty(message.ActorFullName)
                    ? $"Vaša rezervacija za nekretninu \"{message.PropertyName}\" je otkazana. Razlog: {message.CancellationReason}"
                    : $"Vaša rezervacija za nekretninu \"{message.PropertyName}\" je otkazana od strane {message.ActorFullName}. Razlog: {message.CancellationReason}";

                var clientNotifId = await _notificationWriter.WriteAsync(
                    message.ClientUserId, message.ReservationId,
                    title: "Rezervacija otkazana",
                    clientText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);

                PublishPush(clientNotifId, message.ClientUserId, message.ReservationId,
                    "Rezervacija otkazana", clientText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);
            }

            if (message.RenterUserId.HasValue && message.RenterUserId.Value > 0)
            {
                var renterText = string.IsNullOrEmpty(message.ActorFullName)
                    ? $"Rezervacija \"{message.ReservationNumber}\" za nekretninu \"{message.PropertyName}\" je otkazana. Razlog: {message.CancellationReason}"
                    : $"Rezervacija \"{message.ReservationNumber}\" za nekretninu \"{message.PropertyName}\" je otkazana od strane {message.ActorFullName}. Razlog: {message.CancellationReason}";

                var renterNotifId = await _notificationWriter.WriteAsync(
                    message.RenterUserId.Value, message.ReservationId,
                    title: "Rezervacija otkazana",
                    renterText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);

                PublishPush(renterNotifId, message.RenterUserId.Value, message.ReservationId,
                    "Rezervacija otkazana", renterText,
                    message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);
            }
        }, nameof(OnReservationCancelled));
    }

    private async Task OnReservationNotification(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        var message = JsonConvert.DeserializeObject<ReservationNotificationMessage>(body);
        if (message is null)
        {
            _logger.LogWarning("Received null/unparseable message on {Queue}. Discarding.", NotificationQueue);
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
            return;
        }

        await ExecuteWithRetryAsync(ea, async () =>
        {
            _logger.LogInformation("Creating notification for user {UserId}, reservation {ReservationNumber}",
                message.UserId, message.ReservationNumber);

            var notifId = await _notificationWriter.WriteAsync(
                message.UserId, message.ReservationId,
                message.Title,
                message.Message,
                message.ReservationNumber,
                message.PropertyName,
                message.PropertyPhotoUrl);

            PublishPush(notifId, message.UserId, message.ReservationId,
                message.Title, message.Message,
                message.ReservationNumber, message.PropertyName, message.PropertyPhotoUrl);
        }, nameof(OnReservationNotification));
    }

    private async Task OnPasswordReset(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        var message = JsonConvert.DeserializeObject<PasswordResetMessage>(body);
        if (message is null)
        {
            _logger.LogWarning("Received null/unparseable message on {Queue}. Discarding.", PasswordResetQueue);
            _channel!.BasicNack(ea.DeliveryTag, false, requeue: false);
            return;
        }

        await ExecuteWithRetryAsync(ea, async () =>
        {
            _logger.LogInformation("Sending password reset OTP to {Email}", message.Email);
            await _emailService.SendPasswordResetAsync(message.Email, message.FullName, message.Otp);
        }, nameof(OnPasswordReset));
    }

    private void PublishPush(int notificationId, int userId, int? reservationId,
        string? title, string message,
        string? reservationNumber, string? propertyName, string? propertyPhotoUrl)
    {
        try
        {
            var payload = JsonConvert.SerializeObject(new
            {
                Id               = notificationId,
                UserId           = userId,
                ReservationId    = reservationId,
                Title            = title,
                Message          = message,
                ReservationNumber = reservationNumber,
                PropertyName     = propertyName,
                PropertyPhotoUrl = propertyPhotoUrl,
                CreatedAt        = DateTime.UtcNow
            });
            var props = _channel!.CreateBasicProperties();
            props.Persistent = true;
            _channel.BasicPublish(Exchange, "notification.push", props,
                Encoding.UTF8.GetBytes(payload));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to publish push message for user {UserId}", userId);
        }
    }

    public override void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
        base.Dispose();
    }
}
