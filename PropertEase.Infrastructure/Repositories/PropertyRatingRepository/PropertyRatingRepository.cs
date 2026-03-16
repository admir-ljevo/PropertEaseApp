using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyRating;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PropertyRatingRepository
{
    public class PropertyRatingRepository : BaseRepository<PropertyRating, int>, IPropertyRatingRepository
    {
        public PropertyRatingRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyRatingDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr => pr.Id == id));
        }

        public async Task<List<PropertyRatingDto>> GetByName(string name)
        {
            return await ProjectToListAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr => pr.Property.Name == name));
        }

       public async new Task<List<PropertyRatingDto>> GetAllAsync()
       {
            return await DatabaseContext.PropertyRatings
                .AsNoTracking()
                .Where(pr => !pr.IsDeleted)
                .Select(pr => new PropertyRatingDto
                {
                    Id = pr.Id,
                    CreatedAt = pr.CreatedAt,
                    ModifiedAt = pr.ModifiedAt,
                    IsDeleted = pr.IsDeleted,
                    PropertyId = pr.PropertyId,
                    ReviewerId = pr.ReviewerId,
                    ReviewerName = pr.ReviewerName,
                    Rating = pr.Rating,
                    Description = pr.Description,
                    Reviewer = pr.Reviewer == null ? null : new Core.Dto.ApplicationUser.ApplicationUserDto
                    {
                        Id = pr.Reviewer.Id,
                        Person = pr.Reviewer.Person == null ? null : new Core.Dto.Person.PersonDto
                        {
                            Id = pr.Reviewer.Person.Id,
                            FirstName = pr.Reviewer.Person.FirstName,
                            LastName = pr.Reviewer.Person.LastName,
                            ProfilePhotoBytes = pr.Reviewer.Person.ProfilePhotoBytes,
                        }
                    }
                })
                .ToListAsync();
       }

        public async Task<List<PropertyRatingDto>> GetByPropertyId(int id)
        {
            return await DatabaseContext.PropertyRatings
                .AsNoTracking()
                .Where(pr => pr.PropertyId == id && !pr.IsDeleted)
                .Select(pr => new PropertyRatingDto
                {
                    Id = pr.Id,
                    CreatedAt = pr.CreatedAt,
                    ModifiedAt = pr.ModifiedAt,
                    IsDeleted = pr.IsDeleted,
                    PropertyId = pr.PropertyId,
                    ReviewerId = pr.ReviewerId,
                    ReviewerName = pr.ReviewerName,
                    Rating = pr.Rating,
                    Description = pr.Description,
                    Reviewer = pr.Reviewer == null ? null : new Core.Dto.ApplicationUser.ApplicationUserDto
                    {
                        Id = pr.Reviewer.Id,
                        Person = pr.Reviewer.Person == null ? null : new Core.Dto.Person.PersonDto
                        {
                            Id = pr.Reviewer.Person.Id,
                            FirstName = pr.Reviewer.Person.FirstName,
                            LastName = pr.Reviewer.Person.LastName,
                            ProfilePhotoBytes = pr.Reviewer.Person.ProfilePhotoBytes,
                        }
                    }
                })
                .ToListAsync();
        }

        public async Task<double> GetAverageRatingAsync(int propertyId)
        {
            return await DatabaseContext.PropertyRatings
                .Where(pr => pr.PropertyId == propertyId && !pr.IsDeleted)
                .AverageAsync(pr => (double?)pr.Rating) ?? 0;
        }

        public async Task<PagedResult<PropertyRatingDto>> GetFiltered(RatingsFilter filter)
        {
            var query = DatabaseContext.PropertyRatings
                .AsNoTracking()
                .Where(pr =>
                    pr.PropertyId == filter.PropertyId
                    && !pr.IsDeleted
                    && (!filter.CreatedFrom.HasValue || filter.CreatedFrom <= pr.CreatedAt)
                    && (!filter.CreatedTo.HasValue || filter.CreatedTo >= pr.CreatedAt));

            var totalCount = await query.CountAsync();

            IQueryable<PropertyRating> ordered = filter.SortByRating == "asc"
                ? query.OrderBy(pr => pr.Rating)
                : filter.SortByRating == "desc"
                    ? query.OrderByDescending(pr => pr.Rating)
                    : query.OrderByDescending(pr => pr.CreatedAt);

            var items = await ordered
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(pr => new PropertyRatingDto
                {
                    Id = pr.Id,
                    CreatedAt = pr.CreatedAt,
                    ModifiedAt = pr.ModifiedAt,
                    IsDeleted = pr.IsDeleted,
                    PropertyId = pr.PropertyId,
                    ReviewerId = pr.ReviewerId,
                    ReviewerName = pr.ReviewerName,
                    Rating = pr.Rating,
                    Description = pr.Description,
                    Reviewer = pr.Reviewer == null ? null : new Core.Dto.ApplicationUser.ApplicationUserDto
                    {
                        Id = pr.Reviewer.Id,
                        Person = pr.Reviewer.Person == null ? null : new Core.Dto.Person.PersonDto
                        {
                            Id = pr.Reviewer.Person.Id,
                            FirstName = pr.Reviewer.Person.FirstName,
                            LastName = pr.Reviewer.Person.LastName,
                            ProfilePhotoBytes = pr.Reviewer.Person.ProfilePhotoBytes,
                        }
                    }
                })
                .ToListAsync();

            return new PagedResult<PropertyRatingDto> { Items = items, TotalCount = totalCount };
        }
    }
}
