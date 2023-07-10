using MobiFon.Core.Dto.Property;
using MobiFon.Core.Filters;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PropertyService
{
    public interface IPropertyService: IBaseService<PropertyDto>
    {
        public Task<List<PropertyDto>> GetByNameAsync(string name);
        public Task<List<PropertyDto>> GetFilteredData(PropertyFilter filter);
    }
}
