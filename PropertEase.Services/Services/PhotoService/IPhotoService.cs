using PropertEase.Core.Dto.Photo;
using PropertEase.Infrastructure;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PhotoService
{
    public interface IPhotoService: IBaseService<PhotoDto>
    {
        Task<List<PhotoDto>> GetByPropertyId(int id);
        Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId);
        Task<PhotoDto> GetFirstImageByProperty(int propertyId);
        

    }
}
