using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Controllers;
using MobiFon.Core.Dto.City;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;
using PropertEase.Core.Dto.City;
using PropertEase.Services.Services.CityService;

namespace PropertEase.Controllers
{
    public class CityController : BaseController<CityDto, CityUpsertDto, CityUpsertDto, BaseSearchObject>
    {
        private readonly ICityService cityService;
        public CityController(ICityService baseService, IMapper mapper) : base(baseService, mapper)
        {
            cityService = baseService;
        }
    }
}
