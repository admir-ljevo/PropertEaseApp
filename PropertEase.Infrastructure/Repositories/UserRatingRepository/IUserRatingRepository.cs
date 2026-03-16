using PropertEase.Core.Dto;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Entities;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.UserRatingRepository
{
    public interface IUserRatingRepository : IBaseRepository<UserRating, int>
    {
        new Task<List<UserRatingDto>> GetAllAsync();
        Task<UserRatingDto> GetByRatingIdAsync(int id);
        Task<PagedResult<UserRatingDto>> GetFiltered(UserRatingFilter filter);
        Task<double> GetAverageRatingAsync(int renterId);
    }
}
