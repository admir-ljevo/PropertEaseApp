using PropertEase.Core.Dto.Message;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.MessageRepository
{
    public interface IMessageRepository: IBaseRepository<Message, int>
    {
        Task<MessageDto> GetByIdAsync(int id);
        Task<List<MessageDto>> GetByConversationId(int conversationId);
        Task MarkConversationAsRead(int conversationId, int recipientId);
        Task<int> GetUnreadCount(int recipientId);
    }
}
