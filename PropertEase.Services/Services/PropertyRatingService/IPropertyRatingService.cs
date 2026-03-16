using PropertEase.Core.Dto;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyRating;
using PropertEase.Services.Services.BaseService;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyRatingService
{
    public interface IPropertyRatingService: IBaseService<PropertyRatingDto>
    {
        public Task<List<PropertyRatingDto>> GetByNameAsync(string name);
        Task<PagedResult<PropertyRatingDto>> GetFiltered(RatingsFilter filter);

    }
}
