using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.Photo;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.PhotoService;
using Swashbuckle.AspNetCore.Annotations;

namespace MobiFon.Controllers
{

    public class PhotoController : BaseController<PhotoDto, PhotoUpsertDto, PhotoUpsertDto, BaseSearchObject>
    {
        private readonly IPhotoService photoService;
        private readonly IFileManager fileManager;
        private readonly IMapper mapper;
        public PhotoController(IPhotoService baseService, IMapper mapper, IFileManager fileManager) : base(baseService, mapper)
        {
            photoService = baseService;
            this.mapper= mapper;
            this.fileManager = fileManager;
        }
        [HttpPost("Add")]
        public async Task<PhotoDto> Add([FromForm] PhotoUpsertDto photoDto)
        {
            var file = photoDto.File;
            byte[] imageBytes = null;

            if (file != null)
                imageBytes = await fileManager.UploadFileAsBase64String(file);

            photoDto.ImageBytes = imageBytes;

            return await photoService.AddAsync(mapper.Map<PhotoDto>(photoDto));
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
