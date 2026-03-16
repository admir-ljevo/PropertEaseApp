using PropertEase.Core.Dto.Property;
using PropertEase.Core.Filters;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyService
{
    public interface IPropertyService: IBaseService<PropertyDto>
    {
        public Task<List<PropertyDto>> GetByNameAsync(string name);
        public Task<PropertEase.Core.Dto.PagedResult<PropertyListDto>> GetFilteredData(PropertyFilter filter);
        public Task<List<PropertyRecommendationDto>> GetRecommendedPropertiesAsync(int propertyId);
    }
}
