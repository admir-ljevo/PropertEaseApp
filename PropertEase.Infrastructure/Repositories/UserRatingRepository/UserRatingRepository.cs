using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Entities;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.UserRatingRepository
{
    public class UserRatingRepository : BaseRepository<UserRating, int>, IUserRatingRepository
    {
        public UserRatingRepository(IMapper mapper, DatabaseContext databaseContext)
            : base(mapper, databaseContext) { }

        public async new Task<List<UserRatingDto>> GetAllAsync()
        {
            return await GetFiltered(new UserRatingFilter { PageSize = int.MaxValue })
                .ContinueWith(t => t.Result.Items);
        }

        public async Task<UserRatingDto> GetByRatingIdAsync(int id)
        {
            return await DatabaseContext.UserRatings
                .AsNoTracking()
                .Where(r => r.Id == id && !r.IsDeleted)
                .Select(r => new UserRatingDto
                {
                    Id = r.Id,
                    CreatedAt = r.CreatedAt,
                    RenterId = r.RenterId,
                    ReviewerId = r.ReviewerId,
                    ReviewerName = r.ReviewerName,
                    Rating = r.Rating,
                    Description = r.Description,
                })
                .FirstOrDefaultAsync() ?? new UserRatingDto();
        }

        public async Task<double> GetAverageRatingAsync(int renterId)
        {
            return await DatabaseContext.UserRatings
                .Where(r => r.RenterId == renterId && !r.IsDeleted)
                .AverageAsync(r => (double?)r.Rating) ?? 0;
        }

        public async Task<PagedResult<UserRatingDto>> GetFiltered(UserRatingFilter filter)
        {
            var query = DatabaseContext.UserRatings
                .AsNoTracking()
                .Where(r => !r.IsDeleted &&
                    (!filter.RenterId.HasValue || r.RenterId == filter.RenterId));

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(r => new UserRatingDto
                {
                    Id = r.Id,
                    CreatedAt = r.CreatedAt,
                    ModifiedAt = r.ModifiedAt,
                    IsDeleted = r.IsDeleted,
                    RenterId = r.RenterId,
                    ReviewerId = r.ReviewerId,
                    ReviewerName = r.ReviewerName,
                    Rating = r.Rating,
                    Description = r.Description,
                    Reviewer = r.Reviewer == null ? null : new Core.Dto.ApplicationUser.ApplicationUserDto
                    {
                        Id = r.Reviewer.Id,
                        Person = r.Reviewer.Person == null ? null : new Core.Dto.Person.PersonDto
                        {
                            Id = r.Reviewer.Person.Id,
                            FirstName = r.Reviewer.Person.FirstName,
                            LastName = r.Reviewer.Person.LastName,
                            ProfilePhotoBytes = r.Reviewer.Person.ProfilePhotoBytes,
                        }
                    }
                })
                .ToListAsync();

            return new PagedResult<UserRatingDto> { Items = items, TotalCount = totalCount };
        }
    }
}
