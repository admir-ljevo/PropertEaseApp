using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.Entities;
using MobiFon.Core.Filters;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyRepository
{
    public interface IPropertyRepository: IBaseRepository<Property, int>
    {
        new Task<List<PropertyDto>> GetAllAsync();
        Task<List<PropertyDto>> GetByName(string name);
        Task<PropertyDto> GetByIdAsync(int id);

        Task<List<PropertyDto>> GetFilteredData(PropertyFilter filter);

        Task<List<PropertyDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offeset)
                   => throw new NotImplementedException();
    }
}
