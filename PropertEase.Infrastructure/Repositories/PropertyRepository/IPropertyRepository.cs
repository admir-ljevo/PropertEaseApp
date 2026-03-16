using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.Entities;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PropertyRepository
{
    public interface IPropertyRepository: IBaseRepository<Property, int>
    {
        new Task<List<PropertyDto>> GetAllAsync();
        Task<List<PropertyDto>> GetByName(string name);
        Task<PropertyDto> GetByIdAsync(int id);

        Task<PropertEase.Core.Dto.PagedResult<PropertyListDto>> GetFilteredData(PropertyFilter filter);
        Task UpdateAverageRating(int propertyId, double averageRating);
        Task<List<PropertyRecommendationDto>> GetByIdsAsync(IReadOnlyList<int> ids);

        Task<List<PropertyDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offeset)
                   => throw new NotImplementedException();
    }
}
