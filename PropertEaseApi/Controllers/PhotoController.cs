using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Photo;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.FileManager;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.PhotoService;
using Swashbuckle.AspNetCore.Annotations;

namespace PropertEase.Controllers
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

            if (file != null)
                photoDto.Url = await fileManager.UploadFile(file);

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
