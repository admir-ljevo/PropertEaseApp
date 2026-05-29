using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PropertyTypeRepository
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
            return await ProjectToListAsync<PropertyTypeDto>(DatabaseContext.PropertyTypes.Where(pt => !pt.IsDeleted));
        }

        public async Task<(List<PropertyTypeDto> items, int totalCount)> GetFilteredAsync(string? search, int page, int pageSize)
        {
            var query = DatabaseContext.PropertyTypes.Where(pt => !pt.IsDeleted);
            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(pt => pt.Name != null && pt.Name.Contains(search));
            var totalCount = await query.CountAsync();
            var items = await ProjectToListAsync<PropertyTypeDto>(query.OrderBy(pt => pt.Name).Skip((page - 1) * pageSize).Take(pageSize));
            return (items, totalCount);
        }
    }
}
