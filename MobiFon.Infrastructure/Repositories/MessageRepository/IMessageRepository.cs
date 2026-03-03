using MobiFon.Core.Dto.Message;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.MessageRepository
{
    public interface IMessageRepository: IBaseRepository<Message, int>
    {
        Task<MessageDto> GetByIdAsync(int id);
        Task<List<MessageDto>> GetByConversationId(int conversationId);
    }
}
