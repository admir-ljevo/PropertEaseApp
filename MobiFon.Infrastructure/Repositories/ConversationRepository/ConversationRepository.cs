using AutoMapper;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Conversation;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;

namespace MobiFon.Infrastructure.Repositories.ConversationRepository
{
    public class ConversationRepository : BaseRepository<Conversation, int>, IConversationRepository
    {
        public ConversationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public Task<ConversationDto> GetByIdAync(int id)
        {
            return ProjectToFirstOrDefaultAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => !c.IsDeleted && c.Id == id));
        }

        public async Task<List<ConversationDto>> GetByPropertyAndRenter(int? propertyId, int renterId)
        {
            var query = DatabaseContext.Conversations
                .Where(c => c.RenterId == renterId && !c.IsDeleted);

            if (propertyId.HasValue)
            {
                query = query.Where(c => c.PropertyId == propertyId);
            }

            return await ProjectToListAsync<ConversationDto>(
                query.Select(c => new ConversationDto
                {
                    PropertyId = c.PropertyId,
                    Property = new PropertyDto
                    {
                        Name = c.Property.Name,
                    },
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
                }).OrderByDescending(x=>x.LastSent)
            );
        }




        public async Task<List<ConversationDto>> GetByPropertyId(int id)
        {
            return await ProjectToListAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => c.PropertyId == id && !c.IsDeleted));
        }

        public async Task<List<ConversationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<ConversationDto>(DatabaseContext.Conversations.Where(c => !c.IsDeleted));
        }

        public async Task<List<ConversationDto>> GetByClient(int clientId)
        {
            return await ProjectToListAsync<ConversationDto>(
                    DatabaseContext.Conversations
                        .Where(c => c.ClientId == clientId && !c.IsDeleted).OrderByDescending(x=>x.LastSent)
                        .Select(c => new ConversationDto
                        {
                            PropertyId = c.PropertyId,
                            Property = null,
                            Id = c.Id,
                            ClientId = c.ClientId,
                            RenterId = c.RenterId,
                            LastMessage = c.LastMessage, LastSent = c.LastSent,
                            Client = new ApplicationUserDto
                            {
                                // Include only the necessary fields from the Client property
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
                                // Include only the necessary fields from the Renter property
                                Person = new PersonDto
                                {
                                    FirstName = c.Renter.Person.FirstName,
                                    LastName = c.Renter.Person.LastName,
                                    ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes

                                },
                                UserName = c.Renter.UserName,
                            }
                        })
                );
        }

        public async Task<ConversationDto> GetLastByClient(int clientId)
        {
            return await ProjectToFirstOrDefaultAsync<ConversationDto>(
                DatabaseContext.Conversations
                    .Where(c => c.ClientId == clientId && !c.IsDeleted)
                    .OrderByDescending(c => c.Id)  // Order by ID in descending order
                    .Select(c => new ConversationDto
                    {
                        PropertyId = c.PropertyId,
                        Property = null,
                        Id = c.Id,
                        ClientId = c.ClientId,
                        RenterId = c.RenterId,
                        LastMessage = c.LastMessage,
                        LastSent = c.LastSent,
                        Client = new ApplicationUserDto
                        {
                            // Include only the necessary fields from the Client property
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
                            // Include only the necessary fields from the Renter property
                            Person = new PersonDto
                            {
                                FirstName = c.Renter.Person.FirstName,
                                LastName = c.Renter.Person.LastName,
                                ProfilePhotoBytes = c.Renter.Person.ProfilePhotoBytes
                            },
                            UserName = c.Renter.UserName,
                        }
                    })
            );
        }

    }
}
