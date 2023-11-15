using MobiFon.Core.Dto.Conversation;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.ConversationService
{
    public interface IConversationService: IBaseService<ConversationDto>
    {
        Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId);
        Task<List<ConversationDto>> GetByPropertyId(int id);
        Task<List<ConversationDto>> GetByClient(int clientId);
        Task<ConversationDto> GetLastByClient(int clientId);


    }
}
