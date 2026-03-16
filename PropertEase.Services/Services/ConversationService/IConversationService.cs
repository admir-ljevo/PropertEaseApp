using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Conversation;
using PropertEase.Services.Services.BaseService;

namespace PropertEase.Services.Services.ConversationService
{
    public interface IConversationService: IBaseService<ConversationDto>
    {
        Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId);
        Task<List<ConversationDto>> GetByPropertyId(int id);
        Task<List<ConversationDto>> GetByClient(int clientId);
        Task<ConversationDto> GetLastByClient(int clientId);
        Task<List<ConversationDto>> GetAdminConversations(int userId);
        Task<List<ApplicationUserDto>> GetAdmins();
    }
}
