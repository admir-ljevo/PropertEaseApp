using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyTypeRepository
{
    public interface IPropertyTypeRepository: IBaseRepository<PropertyType, int>
    {
        new Task<List<PropertyTypeDto>> GetAllAsync();
        Task<List<PropertyTypeDto>> GetByName(string name);
        Task<PropertyTypeDto> GetByIdAsync(int id);
        Task<List<PropertyTypeDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offeset)
                   => throw new NotImplementedException();
    }
}
