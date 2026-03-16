
using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.Message;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Shared.Hubs;

namespace PropertEase.Services.Services.MessageService
{
    public class MessageService : IMessageService
    {

        private readonly UnitOfWork unitOfWork;
        



        public MessageService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }


        public async Task<MessageDto> AddAsyncSignalR(MessageDto entityDto, IHubContext<MessageHub> hubContext)
        {
            // 1. Persist the message
            await unitOfWork.MessageRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();

            // 2. Update conversation metadata + broadcast SignalR in parallel
            //    (direct UPDATE — no extra SELECT round-trip)
            await Task.WhenAll(
                unitOfWork.ConversationRepository.UpdateLastMessageAsync(
                    entityDto.ConversationId, entityDto.Content),
                hubContext.Clients.All.SendAsync("newMessage", entityDto)
            );

            return entityDto;
        }

        public async Task<MessageDto> AddAsync(MessageDto entityDto)
        {
            await unitOfWork.MessageRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            await unitOfWork.ConversationRepository.UpdateLastMessageAsync(
                entityDto.ConversationId, entityDto.Content);
            return entityDto;
        }

        public Task<List<MessageDto>> GetAllAsync()
        {
            throw new NotImplementedException();
        }

        public async Task<List<MessageDto>> GetByConversationId(int conversationId)
        {
            return await unitOfWork.MessageRepository.GetByConversationId(conversationId);
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

        public async Task MarkConversationAsRead(int conversationId, int recipientId)
        {
            await unitOfWork.MessageRepository.MarkConversationAsRead(conversationId, recipientId);
        }

        public async Task<int> GetUnreadCount(int recipientId)
        {
            return await unitOfWork.MessageRepository.GetUnreadCount(recipientId);
        }
    }
}
