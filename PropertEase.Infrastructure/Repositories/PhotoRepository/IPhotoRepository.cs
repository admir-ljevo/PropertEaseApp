using PropertEase.Core.Dto.Photo;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Entities;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PhotoRepository
{
    public interface IPhotoRepository: IBaseRepository<Photo, int>
    {
        new Task<List<PhotoDto>> GetAllAsync();
        Task<List<PropertyDto>> GetByName(string name) => throw new NotImplementedException();
        Task<PhotoDto> GetByIdAsync(int id);
        Task<List<PhotoDto>> GetByPropertyId(int id);
        Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId);
        Task<PhotoDto> GetFirstImageByProperty(int propertyId);
        Task<List<PropertyDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset)
                   => throw new NotImplementedException();
    }
    
    
}
