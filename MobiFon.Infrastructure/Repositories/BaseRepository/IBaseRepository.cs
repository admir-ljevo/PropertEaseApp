using MobiFon.Core.Entities.Base;

namespace MobiFon.Infrastructure.Repositories.BaseRepository
{
    public interface IBaseRepository<TEntity, in TPrimaryKey> where TEntity : class
    {
        Task<List<TEntity>> GetAllAsync();
        Task<TEntity> GetById(int id);
        Task<TEntity> GetByIdAsync(TPrimaryKey id, bool asNoTracking = false);
        Task AddAsync(TEntity entity);
        Task<TDto> AddAsync<TDto>(TDto entityDto);
        Task AddRangeAsync<TDto>(IEnumerable<TDto> entitiesDto);
        Task RemoveByIdAsync(int id, bool isSoft = true);
        Task RemoveRange<TDto>(IEnumerable<TDto> entitiesDto, bool isSoft = true) where TDto : class, IBaseEntity;

        void Update(TEntity entity);
        void Update<TDto>(TDto entity);
        void UpdateRange<TDto>(IEnumerable<TDto> entitiesDto);


    }
}

