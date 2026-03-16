using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.PropertyTypeService;

namespace PropertEase.Controllers
{
    public class PropertyTypeController : BaseController<PropertyTypeDto, PropertyTypeUpsertDto, PropertyTypeUpsertDto, BaseSearchObject>
    {
        public PropertyTypeController(IPropertyTypeService baseService, IMapper mapper) : base(baseService, mapper)
        {
        }
    }
}
