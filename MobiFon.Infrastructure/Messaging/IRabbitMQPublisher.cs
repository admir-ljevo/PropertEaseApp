namespace MobiFon.Infrastructure.Messaging;

public interface IRabbitMQPublisher
{
    void Publish<T>(T message, string routingKey) where T : class;
}
