using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.Notification;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.NotificationRepository
{
    public class NotificationRepository : BaseRepository<Notification, int>, INotificationRepository
    {
        public NotificationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<NotificationDto> GetByIdAsync(int id)
        {
            return await ProjectToSingleOrDefaultAsync<NotificationDto>(DatabaseContext.Notifications.Where(n => n.Id == id && !n.IsDeleted)); 
        }

        public async Task<List<NotificationDto>> GetByNameAsync(string name)
        {
            return await ProjectToListAsync<NotificationDto>(DatabaseContext.Notifications.Where(n=>n.Name.ToLower().Contains(name.ToLower())));    
        }

        public async Task<List<NotificationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<NotificationDto>(DatabaseContext.Notifications.Where(n => !n.IsDeleted));
        }
        //    
        public async Task<PropertEase.Core.Dto.PagedResult<NotificationDto>> GetFiltered(NotificationFilter filter)
        {
            var query = DatabaseContext.Notifications
                .Where(n =>
                    (string.IsNullOrEmpty(filter.Name) || n.Name.Contains(filter.Name)) &&
                    (!filter.CreatedFrom.HasValue || n.CreatedAt >= filter.CreatedFrom) &&
                    (!filter.CreatedTo.HasValue || n.CreatedAt <= filter.CreatedTo) &&
                    !n.IsDeleted
                )
                .OrderByDescending(n => n.CreatedAt);

            var totalCount = await query.CountAsync();
            var items = await ProjectToListAsync<NotificationDto>(
                query.Skip((filter.Page - 1) * filter.PageSize).Take(filter.PageSize));

            return new PropertEase.Core.Dto.PagedResult<NotificationDto> { Items = items, TotalCount = totalCount };
        }
    }
}
