
using MobiFon.Core.Dto.Message;
using MobiFon.Infrastructure.UnitOfWork;

namespace MobiFon.Services.Services.MessageService
{
    public class MessageService : IMessageService
    {

        private readonly UnitOfWork unitOfWork;

        public MessageService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<MessageDto> AddAsync(MessageDto entityDto)
        {
            await unitOfWork.MessageRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public Task<List<MessageDto>> GetAllAsync()
        {
            throw new NotImplementedException();
        }

        public async Task<List<MessageDto>> GetByConversationId(int conversationId, int senderId)
        {
            return await unitOfWork.MessageRepository.GetByConversationId(conversationId, senderId);
        }

        public async Task<MessageDto> GetByIdAsync(int id)
        {
            return await unitOfWork.MessageRepository.GetByIdAsync(id);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.MessageRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(MessageDto entity)
        {
            unitOfWork.MessageRepository.Update(entity);
            unitOfWork.SaveChanges();
        }

        public async Task<MessageDto> UpdateAsync(MessageDto entity)
        {
            unitOfWork.MessageRepository.Update(entity);
            await unitOfWork.SaveChangesAsync();
            return entity;
        }
    }
}
