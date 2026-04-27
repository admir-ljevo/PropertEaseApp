using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Photo;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.PhotoService;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Shared.Constants;
using Swashbuckle.AspNetCore.Annotations;
using System.Security.Claims;

namespace PropertEase.Controllers
{

    public class PhotoController : BaseController<PhotoDto, PhotoUpsertDto, PhotoUpsertDto, BaseSearchObject>
    {
        private readonly IPhotoService photoService;
        private readonly IFileManager fileManager;
        private readonly IPropertyService _propertyService;
        private readonly IMapper mapper;

        public PhotoController(IPhotoService baseService, IMapper mapper, IFileManager fileManager, IPropertyService propertyService) : base(baseService, mapper)
        {
            photoService = baseService;
            this.mapper = mapper;
            this.fileManager = fileManager;
            _propertyService = propertyService;
        }

        [NonAction] public override Task<List<PhotoDto>> Get([FromQuery] int page = 1, [FromQuery] int pageSize = 20) => throw new NotSupportedException();
        [NonAction] public override Task<PhotoDto> Get(int id) => throw new NotSupportedException();
        [NonAction] public override Task<PhotoDto> Post(PhotoUpsertDto insertEntity) => throw new NotSupportedException();
        [NonAction] public override Task<PhotoDto> Put(int id, PhotoUpsertDto updateEntity) => throw new NotSupportedException();

        [Authorize]
        [HttpPost("Add")]
        public async Task<IActionResult> Add([FromForm] PhotoUpsertDto photoDto)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
            var isAdmin = User.IsInRole(AppRoles.Admin);

            if (!isAdmin && photoDto.PropertyId.HasValue)
            {
                var property = await _propertyService.GetByIdAsync(photoDto.PropertyId.Value);
                if (property == null || property.ApplicationUserId != callerId)
                    return Forbid();
            }

            var file = photoDto.File;
            if (file != null)
                photoDto.Url = await fileManager.UploadFile(file);

            return Ok(await photoService.AddAsync(mapper.Map<PhotoDto>(photoDto)));
        }


        [Authorize]
        [HttpDelete("{id}")]
        public override async Task<IActionResult> Delete(int id)
        {
            var callerId = int.TryParse(User.FindFirstValue("Id"), out var parsed) ? parsed : 0;
            var isAdmin = User.IsInRole(AppRoles.Admin);

            if (!isAdmin)
            {
                var photo = await photoService.GetByIdAsync(id);
                if (photo == null) return NotFound();
                if (photo.PropertyId.HasValue)
                {
                    var property = await _propertyService.GetByIdAsync(photo.PropertyId.Value);
                    if (property == null || property.ApplicationUserId != callerId)
                        return Forbid();
                }
            }

            await photoService.RemoveByIdAsync(id);
            return Ok();
        }

        [HttpGet("propertyId/{id}")]
        public async Task<List<PhotoDto>> GetPhotosByProperty(int id)
        {
            return await photoService.GetByPropertyId(id);
        }
        [HttpGet("propertyId/{propertyId}/imageId/{imageId}")]
        public async Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId)
        {
            return await photoService.GetSingleImageByProperty(propertyId, imageId);
        }

        [HttpGet("GetFirstImage/propertyId/{propertyId}")]
        public async Task<PhotoDto> GetFirstImageByProperty(int propertyId)
        {
            return await photoService.GetFirstImageByProperty(propertyId);
        }


    }
}
