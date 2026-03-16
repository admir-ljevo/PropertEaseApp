using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Controllers;
using PropertEase.Core.Dto.Country;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.CountryService;

namespace PropertEaseApi.Controllers
{
    public class CountryController : BaseController<CountryDto, CountryUpsertDto, CountryUpsertDto, BaseSearchObject>
    {
        public CountryController(ICountryService baseService, IMapper mapper) : base(baseService, mapper)
        {
        }
    }
}
