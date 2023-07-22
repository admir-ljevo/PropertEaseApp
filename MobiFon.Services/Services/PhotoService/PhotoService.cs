using MobiFon.Core.Dto.Photo;
using MobiFon.Infrastructure.UnitOfWork;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PhotoService
{
    public class PhotoService : IPhotoService
    {
        private readonly UnitOfWork unitOfWork;

        public PhotoService(IUnitOfWork unitOfWork)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<PhotoDto> AddAsync(PhotoDto entityDto)
        {
            await unitOfWork.PhotoRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<PhotoDto>> GetAllAsync()
        {
            return await unitOfWork.PhotoRepository.GetAllAsync();
        }

        public async Task<PhotoDto> GetByIdAsync(int id)
        {
            return await unitOfWork.PhotoRepository.GetByIdAsync(id);
        }

        public async Task<List<PhotoDto>> GetByPropertyId(int id)
        {
            return await unitOfWork.PhotoRepository.GetByPropertyId(id);
        }

        public async Task<PhotoDto> GetFirstImageByProperty(int propertyId)
        {
            return await unitOfWork.PhotoRepository.GetFirstImageByProperty(propertyId);
        }

        public async Task<PhotoDto> GetSingleImageByProperty(int propertyId, int imageId)
        {
            return await unitOfWork.PhotoRepository.GetSingleImageByProperty(propertyId, imageId);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await unitOfWork.PhotoRepository.RemoveByIdAsync(id, isSoft);
            await unitOfWork.SaveChangesAsync();
        }

        public void Update(PhotoDto entity)
        {
            unitOfWork.PhotoRepository.Update(entity);
            unitOfWork.SaveChanges();
        }
    }
}
