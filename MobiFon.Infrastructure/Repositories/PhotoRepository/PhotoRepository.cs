

using AutoMapper;
using MobiFon.Core.Dto.Photo;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.PhotoRepository
{
    public class PhotoRepository : BaseRepository<Photo, int>, IPhotoRepository
    {
        public PhotoRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PhotoDto> GetByIdAsync(int id)
        {
            var photo = await ProjectToFirstOrDefaultAsync<PhotoDto>(DatabaseContext.Photos.Where(p => p.Id == id));
            return photo;
        }

        public async Task<List<PhotoDto>> GetByPropertyId(int id)
        {
            var photos = await ProjectToListAsync<PhotoDto>(DatabaseContext.Photos.Where(p => p.PropertyId == id));
            return photos;
        }

        public async Task<List<PhotoDto>> GetAllAsync()
        {
            return await ProjectToListAsync<PhotoDto>(DatabaseContext.Photos);
        }

        public async Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId)
        {
            return await ProjectToSingleAsync<PhotoDto>(DatabaseContext.Photos.Where(p=>p.PropertyId==propertyId && p.Id == imageId));
        }

        public async Task<PhotoDto> GetFirstImageByProperty(int propertyId)
        {
            return await ProjectToFirstOrDefaultAsync<PhotoDto>(DatabaseContext.Photos.Where(p => p.PropertyId == propertyId));
        }

    }
}
