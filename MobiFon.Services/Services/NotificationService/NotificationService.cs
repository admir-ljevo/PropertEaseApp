using MobiFon.Core.Dto.Notification;
using MobiFon.Infrastructure.UnitOfWork;


namespace MobiFon.Services.Services.NotificationService
{
    public class NotificationService : INotificationService
    {

        private readonly UnitOfWork unitOfWork;

        public NotificationService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<NotificationDto> AddAsync(NotificationDto entityDto)
        {
            await unitOfWork.NotificationRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<NotificationDto>> GetAllAsync()
        {
            return await unitOfWork.NotificationRepository.GetAllAsync();
        }

        public async Task<NotificationDto> GetByIdAsync(int id)
        {
           return await unitOfWork.NotificationRepository.GetByIdAsync(id); 
        }

        public async Task<List<NotificationDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.NotificationRepository.GetByNameAsync(name);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
           await unitOfWork.MessageRepository.RemoveByIdAsync(id, isSoft);
           await unitOfWork.SaveChangesAsync();
        }

        public void Update(NotificationDto entity)
        {
            unitOfWork.NotificationRepository.Update(entity);
            unitOfWork.SaveChanges();
        }

        public async Task<NotificationDto> UpdateAsync(NotificationDto entity)
        {
            unitOfWork.NotificationRepository.Update(entity);
            await unitOfWork.SaveChangesAsync();
            return entity;
        }

    }
}
