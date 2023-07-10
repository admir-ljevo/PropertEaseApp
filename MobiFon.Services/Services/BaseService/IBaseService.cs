using MobiFon.Core.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.BaseService
{
    public interface IBaseService<EntityDto> where EntityDto: class
    {
        Task<EntityDto> AddAsync(EntityDto entityDto);
        Task<List<EntityDto>> GetAllAsync();
        Task<EntityDto> GetByIdAsync(int id);
        Task RemoveByIdAsync(int id, bool isSoft = true);
        void Update(EntityDto entity);
        Task<EntityDto> UpdateAsync(EntityDto entityDto) => throw new NotImplementedException();
        Task AddRangeAsync(IEnumerable<EntityDto> entitiesDto) => throw new NotImplementedException();
        void UpdateRange(IEnumerable<EntityDto> entitiesDto) => throw new NotImplementedException();
    }

    public interface IPaginationBaseService<EntityDto>
    {
        Task<List<EntityDto>> GetForPaginationAsync(BaseSearchObject baseSearchObject, int pageSize, int offeset);
    }

}
