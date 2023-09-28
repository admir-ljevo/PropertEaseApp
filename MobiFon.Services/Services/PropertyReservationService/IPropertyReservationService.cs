using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Services.Services.BaseService;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.PropertyReservationService
{
    public interface IPropertyReservationService: IBaseService<PropertyReservationDto>
    {
        public Task<List<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter);
    }
}
