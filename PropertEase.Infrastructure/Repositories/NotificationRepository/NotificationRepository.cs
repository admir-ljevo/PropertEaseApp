using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.Notification;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Person;

namespace PropertEase.Infrastructure.Repositories.NotificationRepository
{
    public class NotificationRepository : BaseRepository<Notification, int>, INotificationRepository
    {
        public NotificationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<NotificationDto> GetByIdAsync(int id)
        {
            return await ProjectToSingleOrDefaultAsync<NotificationDto>(
                DatabaseContext.Notifications.Where(n => n.Id == id && !n.IsDeleted));
        }

        public async Task<List<NotificationDto>> GetByNameAsync(string name)
        {
            return await DatabaseContext.Notifications
                .AsNoTracking()
                .Where(n => n.Name.ToLower().Contains(name.ToLower()) && !n.IsDeleted)
                .Take(100)
                .Select(n => new NotificationDto
                {
                    Id = n.Id,
                    CreatedAt = n.CreatedAt,
                    ModifiedAt = n.ModifiedAt,
                    IsDeleted = n.IsDeleted,
                    Name = n.Name,
                    UserId = n.UserId,
                    Image = n.Image,
                    Text = n.Text,
                })
                .ToListAsync();
        }

        public async Task<List<NotificationDto>> GetAllAsync()
        {
            return await DatabaseContext.Notifications
                .AsNoTracking()
                .Where(n => !n.IsDeleted)
                .OrderByDescending(n => n.CreatedAt)
                .Take(100)
                .Select(n => new NotificationDto
                {
                    Id = n.Id,
                    CreatedAt = n.CreatedAt,
                    ModifiedAt = n.ModifiedAt,
                    IsDeleted = n.IsDeleted,
                    Name = n.Name,
                    UserId = n.UserId,
                    Image = n.Image,
                    Text = n.Text,
                })
                .ToListAsync();
        }

        public async Task<PropertEase.Core.Dto.PagedResult<NotificationDto>> GetFiltered(NotificationFilter filter)
        {
            var pageSize = Math.Min(filter.PageSize, 100);
            var query = DatabaseContext.Notifications
                .Where(n =>
                    (string.IsNullOrEmpty(filter.Name) || n.Name.Contains(filter.Name)) &&
                    (!filter.CreatedFrom.HasValue || n.CreatedAt >= filter.CreatedFrom) &&
                    (!filter.CreatedTo.HasValue || n.CreatedAt <= filter.CreatedTo) &&
                    !n.IsDeleted
                )
                .OrderByDescending(n => n.CreatedAt);

            var totalCount = await query.CountAsync();
            var items = await query
                .AsNoTracking()
                .Skip((filter.Page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NotificationDto
                {
                    Id = n.Id,
                    CreatedAt = n.CreatedAt,
                    ModifiedAt = n.ModifiedAt,
                    IsDeleted = n.IsDeleted,
                    Name = n.Name,
                    UserId = n.UserId,
                    Image = n.Image,
                    ImageBytes = n.ImageBytes,
                    Text = n.Text,
                    User = n.User == null ? null : new ApplicationUserDto
                    {
                        Id = n.User.Id,
                        Person = n.User.Person == null ? null : new PersonDto
                        {
                            FirstName = n.User.Person.FirstName,
                            LastName = n.User.Person.LastName,
                        }
                    }
                })
                .ToListAsync();

            return new PropertEase.Core.Dto.PagedResult<NotificationDto> { Items = items, TotalCount = totalCount };
        }
    }
}
