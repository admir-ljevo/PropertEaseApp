using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PropertyRatingService
{
    public interface IPropertyRatingService: IBaseService<PropertyRatingDto>
    {
        public Task<List<PropertyRatingDto>> GetByNameAsync(string name);

    }
}
