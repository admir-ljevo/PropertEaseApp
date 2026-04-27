using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaseController<dtoEntity, dtoInsertEntity, dtoUpdateEntity, dtoSearchObject> : ControllerBase where dtoEntity : class
    {
        private readonly IMapper Mapper;

        protected IBaseService<dtoEntity> BaseService { get; }

        public BaseController(IBaseService<dtoEntity> baseService, IMapper mapper)
        {
            BaseService = baseService;
            Mapper = mapper;
        }

        [HttpGet]
        public virtual async Task<List<dtoEntity>> Get([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            pageSize = Paging.Clamp(pageSize);
            if (BaseService is IPaginationBaseService<dtoEntity> paginated)
                return await paginated.GetForPaginationAsync(null, pageSize, (page - 1) * pageSize);
            var all = await BaseService.GetAllAsync();
            return all.Skip((page - 1) * pageSize).Take(pageSize).ToList();
        }

        [HttpGet("{id:int}")]
        public virtual async Task<dtoEntity> Get(int id)
        {
            return await BaseService.GetByIdAsync(id);
        }

        [HttpGet("{page:int}/{pageSize:int}")]
        public virtual async Task<List<dtoEntity>> Get(int page, int pageSize, [FromQuery] dtoSearchObject search)
        {
            return await ((IPaginationBaseService<dtoEntity>)BaseService).GetForPaginationAsync(search as BaseSearchObject, pageSize, (page - 1) * pageSize);
        }

        [Authorize]
        [HttpPost]
        public virtual async Task<dtoEntity> Post(dtoInsertEntity insertEntity)
        {
            return await BaseService.AddAsync(Mapper.Map<dtoEntity>(insertEntity));
        }

        [Authorize]
        [HttpPut("{id}")]
        public virtual async Task<dtoEntity> Put(int id, dtoUpdateEntity updateEntity)
        {
            return await BaseService.UpdateAsync(Mapper.Map<dtoEntity>(updateEntity));
        }

        [Authorize]
        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            await BaseService.RemoveByIdAsync(id);
            return Ok();
        }

    }
}
