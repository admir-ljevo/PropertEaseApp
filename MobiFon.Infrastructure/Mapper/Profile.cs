using AutoMapper;
using MobiFon.Core.Dto.ApplicationRole;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Dto;
using MobiFon.Core.Entities.Identity;
using MobiFon.Core.Entities;
using MobiFon.Core.Dto.Country;
using MobiFon.Core.Dto.City;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.Dto.PropertyType;
using MobiFon.Core.Dto.Photo;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.Dto.Conversation;
using MobiFon.Core.Dto.Message;
using MobiFon.Core.Dto.Notification;
using PropertEase.Core.Dto.City;

namespace MobiFon.Infrastructure.Mapper
{
    public class Profiles: Profile
    {
        public Profiles()
        {
            #region User

            CreateMap<ApplicationUserRole, ApplicationUserRoleDto>()
                .ForMember(x => x.User, opt => opt.Ignore())
                .ReverseMap();
            CreateMap<ApplicationRole, ApplicationRoleDto>()
                .ReverseMap();

            CreateMap<Person, EntityItemDto>().
                    ForMember(x => x.Id, opt => opt.MapFrom(x => x.Id)).
                    ForMember(x => x.Label, opt => opt.MapFrom(x => x.FirstName + " " + x.LastName));

            CreateMap<PersonDto, Person>().ReverseMap();

            CreateMap<ApplicationUserDto, ApplicationUser>()
                    .ForMember(au => au.Roles, auDto => auDto.MapFrom(x => x.UserRoles))
                    .ReverseMap();

            CreateMap<Person, ApplicationUserDto>().ForMember(au => au.PersonId, p => p.MapFrom(p => p.Id));


            #endregion

            #region Person

            CreateMap<Person, PersonDto>().ReverseMap();

            #endregion

            #region Country
            CreateMap<Country, CountryDto>().ReverseMap();

            #endregion

            #region City
            CreateMap<City, CityDto>().ReverseMap();
            CreateMap<CityDto, CityUpsertDto>().ReverseMap();
            #endregion

            #region PropertyType
            CreateMap<PropertyType, PropertyTypeDto>().ReverseMap();
            CreateMap<PropertyTypeDto, PropertyTypeUpsertDto>().ReverseMap();
            #endregion

            #region Property
            CreateMap<Property, PropertyDto>().ReverseMap();
            CreateMap<PropertyDto, PropertyUpsertDto>().ReverseMap();
            #endregion

            #region PropertyRating
            CreateMap<PropertyRating, PropertyRatingDto>().ReverseMap();
            CreateMap<PropertyRatingDto, PropertyRatingUpsertDto>().ReverseMap();
            #endregion

            #region Photo
            CreateMap<Photo, PhotoDto>().ReverseMap();
            CreateMap<PhotoDto, PhotoUpsertDto>().ReverseMap();
            #endregion

            #region PropertyReservation

            CreateMap<PropertyReservation, PropertyReservationDto>().ReverseMap();
            CreateMap<PropertyReservationDto, PropertyReservationUpsertDto>().ReverseMap();

            #endregion

            #region Conversation

            CreateMap<Conversation, ConversationDto>().ReverseMap();
            CreateMap<ConversationDto, ConversationUpsertDto>().ReverseMap();
            CreateMap<ConversationDto, ConversationDto>(); 


            #endregion

            #region Message
            CreateMap<Message, MessageDto>().ReverseMap();
            CreateMap<MessageDto, MessageUpsertDto>().ReverseMap();
            CreateMap<MessageDto, MessageDto>().ReverseMap();

            #endregion

            #region Notification

            CreateMap<Notification, NotificationDto>().ReverseMap();
            CreateMap<NotificationDto, NotificationUpsertDto>().ReverseMap();

            #endregion


        }

    }
}
