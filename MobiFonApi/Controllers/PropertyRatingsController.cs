using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.PropertyRatingService;
using MobiFon.Services.Services.PropertyService;

namespace MobiFon.Controllers
{
    public class PropertyRatingsController : BaseController<PropertyRatingDto, PropertyRatingUpsertDto, PropertyRatingUpsertDto, BaseSearchObject>
    {
        public PropertyRatingsController(IPropertyRatingService baseService, IMapper mapper) : base(baseService, mapper)
        {
        }
    }
}
