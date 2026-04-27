using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PropertyTypeRepository
{
    public interface IPropertyTypeRepository: IBaseRepository<PropertyType, int>
    {
        new Task<List<PropertyTypeDto>> GetAllAsync();
        Task<List<PropertyTypeDto>> GetByName(string name);
        Task<PropertyTypeDto> GetByIdAsync(int id);
    }
}
