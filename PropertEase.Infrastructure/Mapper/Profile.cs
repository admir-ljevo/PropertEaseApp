using AutoMapper;
using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Dto;
using PropertEase.Core.Entities.Identity;
using PropertEase.Core.Entities;
using PropertEase.Core.Dto.Country;
using PropertEase.Core.Dto.City;
using PropertEase.Core.Dto.Payment;
using PropertEase.Core.Dto.Property;
using PropertEase.Core.Dto.PropertyRating;
using PropertEase.Core.Dto.PropertyType;
using PropertEase.Core.Dto.Photo;
using PropertEase.Core.Dto.PropertyReservation;
using PropertEase.Core.Dto.Conversation;
using PropertEase.Core.Dto.Message;
using PropertEase.Core.Dto.Notification;
using PropertEase.Core.Dto.ReservationNotification;
using PropertEase.Core.Dto.UserRating;
using PropertEase.Core.Dto.City;

namespace PropertEase.Infrastructure.Mapper
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
            CreateMap<CountryDto, CountryUpsertDto>().ReverseMap();

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
            CreateMap<Property, PropertyDto>()
                .ForMember(dest => dest.Photos, opt => opt.MapFrom(src => src.Images));
            CreateMap<PropertyDto, Property>()
                .ForMember(dest => dest.Images, opt => opt.MapFrom(src => src.Photos))
                .ForMember(dest => dest.PropertyReservations, opt => opt.Ignore())
                .ForMember(dest => dest.Ratings, opt => opt.Ignore());
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

            CreateMap<PropertyReservation, PropertyReservationDto>()
                .ReverseMap()
                .ForMember(dest => dest.IsActive, opt => opt.Ignore());

            CreateMap<PropertyReservationDto, PropertyReservationUpsertDto>()
                .ReverseMap()
                .ForMember(dest => dest.IsActive, opt => opt.Ignore());

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

            #region Payment
            CreateMap<Payment, PaymentDto>().ReverseMap();
            #endregion

            #region ReservationNotification
            CreateMap<PropertEase.Core.Entities.ReservationNotification, ReservationNotificationDto>().ReverseMap();
            #endregion

            #region UserRating
            CreateMap<UserRating, UserRatingDto>().ReverseMap();
            CreateMap<UserRatingDto, UserRatingUpsertDto>().ReverseMap();
            #endregion


        }

    }
}
