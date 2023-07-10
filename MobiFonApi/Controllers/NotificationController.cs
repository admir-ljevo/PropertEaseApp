using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.Notification;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.NotificationService;

namespace MobiFon.Controllers
{

    public class NotificationController : BaseController<NotificationDto, NotificationUpsertDto, NotificationUpsertDto, BaseSearchObject>
    {
        private readonly INotificationService notificationService;
        private readonly IFileManager fileManager;
        private readonly IMapper mapper;

        public NotificationController(IFileManager fileManager,INotificationService notificationService, IMapper mapper) : base(notificationService, mapper)
        {
            this.notificationService = notificationService;
            this.mapper = mapper;
            this.fileManager = fileManager;
        }

        [HttpPost("Add")]
        public async Task<NotificationDto> Add([FromForm] NotificationUpsertDto notification)
        {
            var file = notification.file;
            if(file!=null)
                notification.Image = await fileManager.UploadFile(file);
            
            return await notificationService.AddAsync(mapper.Map<NotificationDto>(notification));
        }

        [HttpPut("Edit/{id}")]
        public async Task<NotificationDto> Edit([FromForm] NotificationUpsertDto notification)
        {
            var file = notification.file;
            if (file != null)
                notification.Image = await fileManager.UploadFile(file);
            return await notificationService.UpdateAsync(mapper.Map<NotificationDto>(notification));

        }

    }
}
