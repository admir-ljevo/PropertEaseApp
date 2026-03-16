using PropertEase.Core.Dto;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Filters;
using PropertEase.Services.Services.BaseService;

namespace PropertEase.Services.Services.UserRatingService
{
    public interface IUserRatingService : IBaseService<UserRatingDto>
    {
        Task<PagedResult<UserRatingDto>> GetFiltered(UserRatingFilter filter);
        Task<double> GetAverageRating(int renterId);
    }
}
