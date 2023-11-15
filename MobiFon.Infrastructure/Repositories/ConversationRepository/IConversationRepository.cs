using MobiFon.Core.Dto.Conversation;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.ConversationRepository
{
    public interface IConversationRepository: IBaseRepository<Conversation, int>
    {
        new Task<List<ConversationDto>> GetAllAsync();
        Task<ConversationDto> GetByIdAync(int id);
        Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId);
        Task<List<ConversationDto>> GetByClient( int clientId);
        Task<ConversationDto> GetLastByClient(int clientId);

        Task<List<ConversationDto>> GetByPropertyId(int id);
    }
}
