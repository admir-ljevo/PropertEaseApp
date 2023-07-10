using AutoMapper;
using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using MobiFon.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyTypeRepository
{
    public class PropertyTypeRepository : BaseRepository<PropertyType, int>, IPropertyTypeRepository
    {


        public PropertyTypeRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {

        }

        public Task<PropertyTypeDto> GetByIdAsync(int id)
        {
            return ProjectToFirstOrDefaultAsync<PropertyTypeDto>(DatabaseContext.PropertyTypes.Where(pt => pt.Id == id));
        }

        public async Task<List<PropertyTypeDto>> GetByName(string name)
        {
            return await ProjectToListAsync<PropertyTypeDto>(DatabaseContext.PropertyTypes.Where(pt => pt.Name.ToLower().StartsWith(name.ToLower())));
        }

        public async Task<List<PropertyTypeDto>> GetAllAsync()
        {
            List<PropertyTypeDto> propertyTypeDtos;
            propertyTypeDtos = await ProjectToListAsync<PropertyTypeDto>(DatabaseContext.PropertyTypes.Where(pt => !pt.IsDeleted));
            return propertyTypeDtos;
        }
    }
}
