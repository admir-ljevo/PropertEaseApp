using AutoMapper;
using MobiFon.Core.Dto.Conversation;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.ConversationRepository
{
    public class ConversationRepository : BaseRepository<Conversation, int>, IConversationRepository
    {
        public ConversationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public Task<ConversationDto> GetByIdAync(int id)
        {
            return ProjectToFirstOrDefaultAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => !c.IsDeleted && c.Id == id));
        }

        public async Task<List<ConversationDto>> GetByPropertyAndRenter(int propertyId, int renterId)
        {
            return await ProjectToListAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => c.PropertyId == propertyId && c.RenterId == renterId && !c.IsDeleted));
        }

        public async Task<List<ConversationDto>> GetByPropertyId(int id)
        {
            return await ProjectToListAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => c.PropertyId == id && !c.IsDeleted));
        }

        public async Task<List<ConversationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => !c.IsDeleted));
        }
    }
}
