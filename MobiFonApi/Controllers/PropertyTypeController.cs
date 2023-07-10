using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.PropertyTypeService;

namespace MobiFon.Controllers
{
    public class PropertyTypeController : BaseController<PropertyTypeDto, PropertyTypeUpsertDto, PropertyTypeUpsertDto, BaseSearchObject>
    {
        public PropertyTypeController(IPropertyTypeService baseService, IMapper mapper) : base(baseService, mapper)
        {
        }
    }
}
