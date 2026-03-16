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
            // Always restrict to property conversations (PropertyId != null)
            var query = DatabaseContext.Conversations
                .Where(c => c.RenterId == renterId && !c.IsDeleted && c.PropertyId != null);

            if (propertyId.HasValue)
            {
                query = query.Where(c => c.PropertyId == propertyId);
            }

            return await ProjectToListAsync<ConversationDto>(
                query.Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = new PropertyDto { Name = c.Property.Name },
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    UnreadCount = DatabaseContext.Messages.Count(m =>
                        m.ConversationId == c.Id && m.RecipientId == renterId &&
                        !m.IsRead && !m.IsDeleted),
                    Client = new ApplicationUserDto
                    {
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
                        Person = new PersonDto
                        {
                            FirstName = c.Renter.Person.FirstName,
                            LastName = c.Renter.Person.LastName,
                            ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto
                        },
                        UserName = c.Renter.UserName,
                    }
                }).OrderByDescending(x => x.LastSent)
            );
        }

        public async Task<List<ConversationDto>> GetByPropertyId(int id)
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.PropertyId == id && !c.IsDeleted)
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
                            ProfilePhotoBytes = c.Client.Person.ProfilePhotoBytes
                        },
                        UserName = c.Client.UserName,
                    },
                    Renter = new ApplicationUserDto
                    {
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
                .ToListAsync();
        }

        public async Task<List<ConversationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<ConversationDto>(
                DatabaseContext.Conversations
                    .Where(c => !c.IsDeleted && c.PropertyId != null)
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
                                ProfilePhotoBytes = c.Client.Person.ProfilePhotoBytes
                            },
                            UserName = c.Client.UserName,
                        },
                        Renter = new ApplicationUserDto
                        {
                            Person = new PersonDto
                            {
                                FirstName = c.Renter.Person.FirstName,
                                LastName = c.Renter.Person.LastName,
                                ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes
                            },
                            UserName = c.Renter.UserName,
                        }
                    }).OrderByDescending(x => x.LastSent)
            );
        }

        public async Task<List<ConversationDto>> GetAdminConversations(int userId)
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => !c.IsDeleted && c.PropertyId == null
                            && (c.ClientId == userId || c.RenterId == userId))
                .OrderByDescending(c => c.LastSent)
                .Select(c => new ConversationDto
                {
                    PropertyId = null,
                    Property = null,
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    UnreadCount = DatabaseContext.Messages.Count(m =>
                        m.ConversationId == c.Id && m.RecipientId == userId &&
                        !m.IsRead && !m.IsDeleted),
                    Client = new ApplicationUserDto
                    {
                        Id = c.Client.Id,
                        Person = new PersonDto
                        {
                            FirstName = c.Client.Person.FirstName,
                            LastName = c.Client.Person.LastName,
                            ProfilePhotoBytes = c.Client.Person.ProfilePhotoBytes,
                            ProfilePhoto = c.Client.Person.ProfilePhoto
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
                .ToListAsync();
        }

        public async Task<List<ConversationDto>> GetByClient(int clientId)
        {
            return await DatabaseContext.Conversations
                .AsNoTracking()
                .Where(c => c.ClientId == clientId && !c.IsDeleted)
                .OrderByDescending(c => c.LastSent)
                .Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = c.PropertyId != null ? new PropertyDto { Id = c.Property.Id, Name = c.Property.Name, Address = c.Property.Address } : null,
                    Id = c.Id,
                    ClientId = c.ClientId,
                    RenterId = c.RenterId,
                    LastMessage = c.LastMessage,
                    LastSent = c.LastSent,
                    UnreadCount = DatabaseContext.Messages.Count(m =>
                        m.ConversationId == c.Id && m.RecipientId == clientId &&
                        !m.IsRead && !m.IsDeleted),
                    // Client photo is available locally from Authorization — skip it here
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
                            ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .ToListAsync();
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
                            ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes,
                            ProfilePhoto = c.Renter.Person.ProfilePhoto
                        },
                        UserName = c.Renter.UserName,
                    }
                })
                .FirstOrDefaultAsync();
        }
    }
}
