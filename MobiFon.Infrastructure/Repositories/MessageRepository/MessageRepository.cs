using AutoMapper;
using MobiFon.Core.Dto.Message;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.MessageRepository
{
    public class MessageRepository : BaseRepository<Message, int>, IMessageRepository
    {
        public MessageRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<List<MessageDto>> GetByConversationId(int conversationId, int senderId)
        {
            return await ProjectToListAsync<MessageDto>(DatabaseContext.Messages.Where(m=>m.ConversationId==conversationId && m.SenderId==senderId).OrderBy(m=>m.CreatedAt)); 
            //include soft deleted messages 
        }

        public async Task<MessageDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<MessageDto>(DatabaseContext.Messages.Where(m => m.Id == id && !m.IsDeleted)); 
        }
    }
}
