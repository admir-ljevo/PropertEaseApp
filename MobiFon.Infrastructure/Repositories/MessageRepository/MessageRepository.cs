using AutoMapper;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Message;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.MessageRepository
{
    public class MessageRepository : BaseRepository<Message, int>, IMessageRepository
    {
        public MessageRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<List<MessageDto>> GetByConversationId(int conversationId)
        {
            return await ProjectToListAsync<MessageDto>(
                DatabaseContext.Messages
                    .Where(m => !m.IsDeleted && m.ConversationId == conversationId)
                    .OrderByDescending(m => m.CreatedAt) // or OrderByDescending if you want descending order
                    .Select(m => new MessageDto
                    {
                        Id = m.Id,
                        ConversationId = m.ConversationId,
                        SenderId = m.SenderId, 
                        RecipientId = m.RecipientId,
                        Content = m.Content,
                        CreatedAt = m.CreatedAt, // Assuming MessageDto has a CreatedAt property
                        Sender = new ApplicationUserDto
                        {
                            UserName = m.Sender.UserName,
                            Person = new PersonDto
                            {
                                FirstName = m.Sender.Person.FirstName,
                                LastName = m.Sender.Person.LastName,
                                ProfilePhotoBytes = m.Sender.Person.ProfilePhotoBytes,
                                ProfilePhoto = m.Sender.Person.ProfilePhoto,
                            }

                        },
                        Recipient = new ApplicationUserDto
                        {
                            UserName = m.Recipient.UserName,
                            Person = new PersonDto
                            {
                                FirstName = m.Recipient.Person.FirstName,
                                LastName = m.Recipient.Person.LastName,
                                ProfilePhotoBytes = m.Recipient.Person.ProfilePhotoBytes,
                                ProfilePhoto = m.Recipient.Person.ProfilePhoto,
                            }

                        }
                    })
            );

        }

        public async Task<MessageDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<MessageDto>(DatabaseContext.Messages.Where(m => m.Id == id && !m.IsDeleted));
        }
    }
}
