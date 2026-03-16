using PropertEase.Core.Dto;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Services.UserRatingService
{
    public class UserRatingService : IUserRatingService
    {
        private readonly UnitOfWork _unitOfWork;

        public UserRatingService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<UserRatingDto> AddAsync(UserRatingDto entityDto)
        {
            entityDto.CreatedAt = DateTime.UtcNow;
            await _unitOfWork.UserRatingRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<UserRatingDto>> GetAllAsync()
        {
            return await _unitOfWork.UserRatingRepository.GetAllAsync();
        }

        public async Task<UserRatingDto> GetByIdAsync(int id)
        {
            return await _unitOfWork.UserRatingRepository.GetByRatingIdAsync(id);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await _unitOfWork.UserRatingRepository.RemoveByIdAsync(id, isSoft);
            await _unitOfWork.SaveChangesAsync();
        }

        public void Update(UserRatingDto entity)
        {
            _unitOfWork.UserRatingRepository.Update(entity);
            _unitOfWork.SaveChanges();
        }

        public async Task<UserRatingDto> UpdateAsync(UserRatingDto entity)
        {
            _unitOfWork.UserRatingRepository.Update(entity);
            await _unitOfWork.SaveChangesAsync();
            return entity;
        }

        public async Task<PagedResult<UserRatingDto>> GetFiltered(UserRatingFilter filter)
        {
            return await _unitOfWork.UserRatingRepository.GetFiltered(filter);
        }

        public async Task<double> GetAverageRating(int renterId)
        {
            return await _unitOfWork.UserRatingRepository.GetAverageRatingAsync(renterId);
        }
    }
}
