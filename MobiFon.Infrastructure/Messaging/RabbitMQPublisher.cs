using System.Text;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using RabbitMQ.Client;

namespace MobiFon.Infrastructure.Messaging;

public class RabbitMQPublisher : IRabbitMQPublisher, IDisposable
{
    private readonly RabbitMQSettings _settings;
    private readonly ILogger<RabbitMQPublisher> _logger;
    private IConnection? _connection;
    private IModel? _channel;
    private bool _disposed;

    public RabbitMQPublisher(IOptions<RabbitMQSettings> settings, ILogger<RabbitMQPublisher> logger)
    {
        _settings = settings.Value;
        _logger = logger;
        TryConnect();
    }

    private void TryConnect()
    {
        try
        {
            var factory = new ConnectionFactory
            {
                HostName = _settings.Host,
                Port = _settings.Port,
                UserName = _settings.Username,
                Password = _settings.Password
            };
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();
            _channel.ExchangeDeclare(_settings.Exchange, ExchangeType.Topic, durable: true);
            _logger.LogInformation("Connected to RabbitMQ at {Host}:{Port}", _settings.Host, _settings.Port);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not connect to RabbitMQ. Messages will be dropped until connection is available.");
        }
    }

    public void Publish<T>(T message, string routingKey) where T : class
    {
        if (_channel is null || !_channel.IsOpen)
        {
            _logger.LogWarning("RabbitMQ channel not available. Attempting reconnect...");
            TryConnect();
        }

        if (_channel is null || !_channel.IsOpen)
        {
            _logger.LogError("Failed to publish message to {RoutingKey} - no RabbitMQ connection.", routingKey);
            return;
        }

        try
        {
            var json = JsonConvert.SerializeObject(message);
            var body = Encoding.UTF8.GetBytes(json);

            var props = _channel.CreateBasicProperties();
            props.Persistent = true;
            props.ContentType = "application/json";
            props.Type = typeof(T).Name;

            _channel.BasicPublish(
                exchange: _settings.Exchange,
                routingKey: routingKey,
                basicProperties: props,
                body: body);

            _logger.LogInformation("Published {MessageType} to routing key {RoutingKey}", typeof(T).Name, routingKey);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing message to {RoutingKey}", routingKey);
            throw;
        }
    }

    public void Dispose()
    {
        if (_disposed) return;
        _channel?.Close();
        _connection?.Close();
        _disposed = true;
    }
}
