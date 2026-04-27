using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Message;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.MessageRepository
{
    public class MessageRepository : BaseRepository<Message, int>, IMessageRepository
    {
        public MessageRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<List<MessageDto>> GetAllAsync()
        {
            return await DatabaseContext.Messages
                .AsNoTracking()
                .Where(m => !m.IsDeleted)
                .OrderByDescending(m => m.CreatedAt)
                .Select(m => new MessageDto
                {
                    Id = m.Id,
                    ConversationId = m.ConversationId,
                    SenderId = m.SenderId,
                    RecipientId = m.RecipientId,
                    Content = m.Content,
                    CreatedAt = m.CreatedAt,
                    IsRead = m.IsRead,
                })
                .ToListAsync();
        }

        public async Task<List<MessageDto>> GetByConversationId(int conversationId, int page = 1, int pageSize = 30)
        {
            pageSize = Math.Min(pageSize <= 0 ? 30 : pageSize, 50);
            page = page <= 0 ? 1 : page;
            return await DatabaseContext.Messages
                .AsNoTracking()
                .Where(m => !m.IsDeleted && m.ConversationId == conversationId)
                .OrderByDescending(m => m.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new MessageDto
                {
                    Id = m.Id,
                    ConversationId = m.ConversationId,
                    SenderId = m.SenderId,
                    RecipientId = m.RecipientId,
                    Content = m.Content,
                    CreatedAt = m.CreatedAt,
                    IsRead = m.IsRead,
                    Sender = new ApplicationUserDto
                    {
                        Id = m.Sender.Id,
                        UserName = m.Sender.UserName,
                        Person = new PersonDto
                        {
                            FirstName = m.Sender.Person.FirstName,
                            LastName = m.Sender.Person.LastName,
                        }
                    },
                    Recipient = new ApplicationUserDto
                    {
                        Id = m.Recipient.Id,
                        UserName = m.Recipient.UserName,
                        Person = new PersonDto
                        {
                            FirstName = m.Recipient.Person.FirstName,
                            LastName = m.Recipient.Person.LastName,
                        }
                    },
                })
                .ToListAsync();
        }

        public async Task<MessageDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<MessageDto>(DatabaseContext.Messages.Where(m => m.Id == id && !m.IsDeleted));
        }

        public async Task MarkConversationAsRead(int conversationId, int recipientId)
        {
            await DatabaseContext.Messages
                .Where(m => m.ConversationId == conversationId && m.RecipientId == recipientId && !m.IsRead && !m.IsDeleted)
                .ExecuteUpdateAsync(s => s.SetProperty(m => m.IsRead, true));
        }

        public async Task<int> GetUnreadCount(int recipientId)
        {
            return await DatabaseContext.Messages
                .Where(m => m.RecipientId == recipientId && !m.IsRead && !m.IsDeleted)
                .Select(m => m.ConversationId)
                .Distinct()
                .CountAsync();
        }
    }
}
