using PropertEase.Core.Dto.Photo;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.PhotoRepository
{
    public interface IPhotoRepository: IBaseRepository<Photo, int>
    {
        new Task<List<PhotoDto>> GetAllAsync();
        Task<PhotoDto> GetByIdAsync(int id);
        Task<List<PhotoDto>> GetByPropertyId(int id);
        Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId);
        Task<PhotoDto> GetFirstImageByProperty(int propertyId);
    }
    
    
}
