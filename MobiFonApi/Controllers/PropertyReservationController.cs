using AutoMapper;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.PropertyReservationService;

namespace MobiFon.Controllers
{
    public class PropertyReservationController : BaseController<PropertyReservationDto, PropertyReservationUpsertDto, PropertyReservationUpsertDto, BaseSearchObject>
    {
        public PropertyReservationController(IPropertyReservationService baseService, IMapper mapper): base(baseService, mapper)
        {

        }
    }
}
