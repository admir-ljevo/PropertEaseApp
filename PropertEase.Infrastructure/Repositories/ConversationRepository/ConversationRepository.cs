using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Conversation;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;

namespace PropertEase.Infrastructure.Repositories.ConversationRepository
{
    public class ConversationRepository : BaseRepository<Conversation, int>, IConversationRepository
    {
        public ConversationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public Task<ConversationDto> GetByIdAync(int id)
        {
            return DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => !c.IsDeleted && c.Id == id)
                .Select(c => new ConversationDto
                {
                    Id = c.Id,
                    PropertyId = c.PropertyId,
                    Property = c.Property == null ? null : new PropertyDto { Id = c.Property.Id, Name = c.Property.Name },
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Id = c.Client.Id,
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhotoBytes = c.Client.Person.ProfilePhotoBytes
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Id = c.Renter.Id,
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId)
        {
            var baseQuery = DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.RenterId == renterId && !c.IsDeleted && c.PropertyId != null);

            if (propertyId.HasValue)
                baseQuery = baseQuery.Where(c => c.PropertyId == propertyId);

            var conversations = await baseQuery
                .OrderByDescending(c => c.LastSent)
                .Take(100)
                .Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = new PropertyDto { Name = c.Property.Name },
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhoto = c.Client.Person.ProfilePhoto,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();

            if (conversations.Count == 0) return conversations;

            var ids = conversations.Select(c => c.Id).ToList();
            var unreadCounts = await DatabaseContext.Messages
                .Where(m => ids.Contains(m.ConversationId) && m.RecipientId == renterId && !m.IsRead && !m.IsDeleted)
                .GroupBy(m => m.ConversationId)
                .Select(g => new { ConversationId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ConversationId, x => x.Count);

            foreach (var c in conversations)
                c.UnreadCount = unreadCounts.GetValueOrDefault(c.Id, 0);

            return conversations;
        }

        public async Task<List<ConversationDto>> GetByPropertyId(int id)
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.PropertyId == id && !c.IsDeleted)
                .OrderByDescending(c => c.LastSent)
                .Take(100)
                .Select(c => new ConversationDto
                {
                    Id = c.Id,
                    PropertyId = c.PropertyId,
                    Property = c.Property == null ? null : new PropertyDto { Id = c.Property.Id, Name = c.Property.Name },
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhoto = c.Client.Person.ProfilePhoto,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();
        }

        public async Task<List<ConversationDto>> GetAllAsync()
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => !c.IsDeleted && c.PropertyId != null)
                .OrderByDescending(c => c.LastSent)
                .Take(100)
                .Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = new PropertyDto { Name = c.Property.Name },
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhoto = c.Client.Person.ProfilePhoto,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();
        }

        public async Task<List<ConversationDto>> GetAdminConversations(int userId)
        {
            var conversations = await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => !c.IsDeleted && c.PropertyId == null
                            && (c.ClientId == userId || c.RenterId == userId))
                .OrderByDescending(c => c.LastSent)
                .Take(100)
                .Select(c => new ConversationDto
                {
                    PropertyId = null,
                    Property = null,
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Id = c.Client.Id,
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhoto = c.Client.Person.ProfilePhoto,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Id = c.Renter.Id,
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();

            if (conversations.Count == 0) return conversations;

            var ids = conversations.Select(c => c.Id).ToList();
            var unreadCounts = await DatabaseContext.Messages
                .Where(m => ids.Contains(m.ConversationId) && m.RecipientId == userId && !m.IsRead && !m.IsDeleted)
                .GroupBy(m => m.ConversationId)
                .Select(g => new { ConversationId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ConversationId, x => x.Count);

            foreach (var c in conversations)
                c.UnreadCount = unreadCounts.GetValueOrDefault(c.Id, 0);

            return conversations;
        }

        public async Task<List<ConversationDto>> GetByClient(int clientId)
        {
            var conversations = await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.ClientId == clientId && !c.IsDeleted)
                .OrderByDescending(c => c.LastSent)
                .Take(100)
                .Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = c.PropertyId != null ? new PropertyDto { Id = c.Property.Id, Name = c.Property.Name, Address = c.Property.Address } : null,
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();

            if (conversations.Count == 0) return conversations;

            var ids = conversations.Select(c => c.Id).ToList();
            var unreadCounts = await DatabaseContext.Messages
                .Where(m => ids.Contains(m.ConversationId) && m.RecipientId == clientId && !m.IsRead && !m.IsDeleted)
                .GroupBy(m => m.ConversationId)
                .Select(g => new { ConversationId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.ConversationId, x => x.Count);

            foreach (var c in conversations)
                c.UnreadCount = unreadCounts.GetValueOrDefault(c.Id, 0);

            return conversations;
        }

        public async Task UpdateLastMessageAsync(int conversationId, string? content)
        {
            await DatabaseContext.Conversations
                .Where(c => c.Id == conversationId)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(c => c.LastMessage, content)
                    .SetProperty(c => c.LastSent, DateTime.Now));
        }

        public async Task<ConversationDto> GetLastByClient(int clientId)
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.ClientId == clientId && !c.IsDeleted)
                .OrderByDescending(c => c.Id)
                .Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = c.PropertyId != null ? new PropertyDto { Id = c.Property.Id, Name = c.Property.Name, Address = c.Property.Address } : null,
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    Client = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto,
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .FirstOrDefaultAsync();
        }
    }
}
