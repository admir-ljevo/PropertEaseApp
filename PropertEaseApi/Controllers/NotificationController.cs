using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Notification;
using PropertEase.Shared.Constants;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.NotificationService;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Core.Filters;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
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

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost("Add")]
        public async Task<NotificationDto> Add([FromForm] NotificationUpsertDto notification)
        {
            var file = notification.File;
            byte[] imageBytes = null;
            if (file != null)
            {
                notification.Image = await fileManager.UploadFile(file);
                imageBytes = await fileManager.UploadFileAsBase64String(file);

            }
            notification.ImageBytes = imageBytes;
            return await notificationService.AddAsync(mapper.Map<NotificationDto>(notification));
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPut("Edit/{id}")]
        public async Task<NotificationDto> Edit(int id, [FromForm] NotificationUpsertDto notification)
        {
            var existing = await notificationService.GetByIdAsync(id);
            if (existing == null)
                throw new KeyNotFoundException($"Notification {id} not found.");

            existing.Name = notification.Name;
            existing.Text = notification.Text;

            var file = notification.File;
            if (file != null)
            {
                existing.Image = await fileManager.UploadFile(file);
                existing.ImageBytes = await fileManager.UploadFileAsBase64String(file);
            }
            // When no new file: existing.Image, existing.ImageBytes, and existing.CreatedAt are preserved.

            return await notificationService.UpdateAsync(existing);
        }
        [HttpGet("GetFilteredData")]
        [SwaggerOperation(OperationId = "GetFilteredData")]
        public async Task<IActionResult> GetDataByFilter([FromQuery] NotificationFilter filter)
        {
            try
            {
                var properties = await notificationService.GetFiltered(filter);
                return Ok(properties);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }


    }
}
