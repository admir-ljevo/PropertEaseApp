using MobiFon.Core.Dto.Conversation;
using MobiFon.Infrastructure.UnitOfWork;

namespace MobiFon.Services.Services.ConversationService
{
    public class ConversationService : IConversationService
    {

        private readonly UnitOfWork unitOfOfWork;

        public ConversationService(IUnitOfWork unitOfOfWork)
        {
            this.unitOfOfWork = (UnitOfWork)unitOfOfWork;
        }

        public async Task<ConversationDto> AddAsync(ConversationDto entityDto)
        {
            await unitOfOfWork.ConversationRepository.AddAsync(entityDto);
            await unitOfOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<ConversationDto>> GetAllAsync()
        {
            return await unitOfOfWork.ConversationRepository.GetAllAsync(); 
        }

        public async Task<List<ConversationDto>> GetByClient(int clientId)
        {
            return await unitOfOfWork.ConversationRepository.GetByClient(clientId);        }

        public async Task<ConversationDto> GetByIdAsync(int id)
        {
            return await unitOfOfWork.ConversationRepository.GetByIdAync(id);
        }

        public async Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId)
        {
           return await unitOfOfWork.ConversationRepository.GetByPropertyAndRenter(propertyId, renterId);   
        }

        public async Task<List<ConversationDto>> GetByPropertyId(int id)
        {
            return await unitOfOfWork.ConversationRepository.GetByPropertyId(id);
        }

        public async Task<ConversationDto> GetLastByClient(int clientId)
        {
            return await unitOfOfWork.ConversationRepository.GetLastByClient(clientId);        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfOfWork.ConversationRepository.RemoveByIdAsync(id, isSoft);
            await unitOfOfWork.SaveChangesAsync();
        }

        public void Update(ConversationDto entity)
        {
            throw new NotImplementedException();
        }
    }
}
