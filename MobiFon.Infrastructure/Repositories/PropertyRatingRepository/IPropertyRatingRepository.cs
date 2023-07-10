using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyRatingRepository
{
    public interface IPropertyRatingRepository: IBaseRepository<PropertyRating, int>
    {
        new Task<List<PropertyRatingDto>> GetAllAsync();
        Task<List<PropertyRatingDto>> GetByName(string name);
        Task<PropertyRatingDto> GetByIdAsync(int id);
        Task<List<PropertyRatingDto>> GetByPropertyId(int id);
        Task<List<PropertyRatingDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offeset)
                  => throw new NotImplementedException();
    }
}
