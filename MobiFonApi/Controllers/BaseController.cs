using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;

namespace MobiFon.Controllers
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
        public virtual async Task<List<dtoEntity>> Get()
        {
            return await BaseService.GetAllAsync();
        }

        [HttpGet("{id}")]
        public virtual async Task<dtoEntity> Get(int id)
        {
            return await BaseService.GetByIdAsync(id);
        }

        [HttpGet("{page}/{pageSize}")]
        public virtual async Task<List<dtoEntity>> Get(int page, int pageSize, [FromQuery] dtoSearchObject search)
        {
            return await ((IPaginationBaseService<dtoEntity>)BaseService).GetForPaginationAsync(search as BaseSearchObject, pageSize, (page - 1) * pageSize);
        }

        [HttpPost]
        public virtual async Task<dtoEntity> Post(dtoInsertEntity insertEntity)
        {

            return await BaseService.AddAsync(Mapper.Map<dtoEntity>(insertEntity));
        }

        [HttpPut("{id}")]
        public virtual async Task<dtoEntity> Put(int id, dtoUpdateEntity updateEntity)
        {
            return await BaseService.UpdateAsync(Mapper.Map<dtoEntity>(updateEntity));
        }

        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            await BaseService.RemoveByIdAsync(id);
            return Ok();
        }

    }
}
