using PropertEase.Core.Dto.PropertyType;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyTypeService
{
    public interface IPropertyTypeService: IBaseService<PropertyTypeDto>
    {
        public Task<List<PropertyTypeDto>> GetByNameAsync(string name);
    }
}
