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
    public interface IPropertyRatingRepository: IBaseRepository<PropertyRating, int>
    {
        new Task<List<PropertyRatingDto>> GetAllAsync();
        Task<List<PropertyRatingDto>> GetByName(string name);
        Task<PropertyRatingDto> GetByIdAsync(int id);
        Task<List<PropertyRatingDto>> GetByPropertyId(int id);
        Task<double> GetAverageRatingAsync(int propertyId);
        Task<PagedResult<PropertyRatingDto>> GetFiltered(RatingsFilter filter);
    }
}
