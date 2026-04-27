using System.Text;
using Microsoft.AspNetCore.SignalR;
using Newtonsoft.Json;
using PropertEase.Shared.Hubs;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace PropertEase.Api.Workers;

public class NotificationPushWorker : BackgroundService
{
    private readonly IHubContext<MessageHub> _hub;
    private readonly IConfiguration _config;
    private readonly ILogger<NotificationPushWorker> _logger;

    private const string Exchange  = "propertease.exchange";
    private const string Queue     = "notification.push";
    private const string RoutingKey = "notification.push";

    private IConnection? _connection;
    private IModel? _channel;

    public NotificationPushWorker(
        IHubContext<MessageHub> hub,
        IConfiguration config,
        ILogger<NotificationPushWorker> logger)
    {
        _hub    = hub;
        _config = config;
        _logger = logger;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        try
        {
            var factory = new ConnectionFactory
            {
                HostName              = _config["RabbitMQ:Host"]     ?? "localhost",
                Port                  = int.Parse(_config["RabbitMQ:Port"] ?? "5672"),
                UserName              = _config["RabbitMQ:Username"] ?? "guest",
                Password              = _config["RabbitMQ:Password"] ?? "guest",
                DispatchConsumersAsync = true
            };
            _connection = factory.CreateConnection();
            _channel    = _connection.CreateModel();

            _channel.ExchangeDeclare(Exchange, ExchangeType.Topic, durable: true);
            _channel.QueueDeclare(Queue, durable: true, exclusive: false, autoDelete: false);
            _channel.QueueBind(Queue, Exchange, RoutingKey);
            _channel.BasicQos(0, 1, false);

            _logger.LogInformation("NotificationPushWorker connected to RabbitMQ");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "NotificationPushWorker could not connect to RabbitMQ; real-time push disabled");
        }

        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (_channel == null) return;

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.Received += OnPushMessage;
        _channel.BasicConsume(Queue, autoAck: false, consumer);

        while (!stoppingToken.IsCancellationRequested)
            await Task.Delay(1000, stoppingToken);
    }

    private async Task OnPushMessage(object sender, BasicDeliverEventArgs ea)
    {
        var body = Encoding.UTF8.GetString(ea.Body.ToArray());
        try
        {
            var msg = JsonConvert.DeserializeObject<NotificationPushMessage>(body);
            if (msg != null && msg.UserId > 0)
            {
                await _hub.Clients
                    .User(msg.UserId.ToString())
                    .SendAsync("NewNotification", new
                    {
                        msg.Id,
                        msg.UserId,
                        msg.ReservationId,
                        msg.Title,
                        msg.Message,
                        isSeen = false,
                        msg.ReservationNumber,
                        msg.PropertyName,
                        msg.PropertyPhotoUrl,
                        msg.CreatedAt
                    });

                _logger.LogInformation("Pushed SignalR notification to user {UserId}", msg.UserId);
            }
            _channel!.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error pushing SignalR notification");
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

public class NotificationPushMessage
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int? ReservationId { get; set; }
    public string? Title { get; set; }
    public string Message { get; set; } = string.Empty;
    public string? ReservationNumber { get; set; }
    public string? PropertyName { get; set; }
    public string? PropertyPhotoUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}
