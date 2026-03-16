using Microsoft.EntityFrameworkCore.Storage;
using PropertEase.Infrastructure.Repositories.ApplicationRolesRepository;
using PropertEase.Infrastructure.Repositories.ApplicationUserRolesRepository;
using PropertEase.Infrastructure.Repositories.ApplicationUsersRepository;
using PropertEase.Infrastructure.Repositories.ConversationRepository;
using PropertEase.Infrastructure.Repositories.MessageRepository;
using PropertEase.Infrastructure.Repositories.NotificationRepository;
using PropertEase.Infrastructure.Repositories.PaymentRepository;
using PropertEase.Infrastructure.Repositories.PersonsRepository;
using PropertEase.Infrastructure.Repositories.PhotoRepository;
using PropertEase.Infrastructure.Repositories.PropertyRatingRepository;
using PropertEase.Infrastructure.Repositories.PropertyRepository;
using PropertEase.Infrastructure.Repositories.PropertyReservationRepository;
using PropertEase.Infrastructure.Repositories.PropertyTypeRepository;
using PropertEase.Infrastructure.Repositories.CountryRepository;
using PropertEase.Infrastructure.Repositories.ReservationNotificationRepository;
using PropertEase.Infrastructure.Repositories.CityRepository;
using PropertEase.Infrastructure.Repositories.UserRatingRepository;

namespace PropertEase.Infrastructure.UnitOfWork
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly DatabaseContext _databaseContext;
        public readonly IApplicationUsersRepository ApplicationUsersRepository;
        public readonly IApplicationUserRolesRepository ApplicationUserRolesRepository;
        public readonly IApplicationRolesRepository ApplicationRolesRepository;
        public readonly IPersonsRepository PersonsRepository;
        public readonly IPropertyTypeRepository PropertyTypeRepository;
        public readonly IPropertyRepository PropertyRepository;
        public readonly IPropertyRatingRepository PropertyRatingRepository;
        public readonly IPhotoRepository PhotoRepository;
        public readonly IPropertyReservationRepository PropertyReservationRepository;
        public readonly IConversationRepository ConversationRepository;
        public readonly IMessageRepository MessageRepository;
        public readonly INotificationRepository NotificationRepository;
        public readonly ICityRepository CityRepository;
        public readonly ICountryRepository CountryRepository;
        public readonly IPaymentRepository PaymentRepository;
        public readonly IReservationNotificationRepository ReservationNotificationRepository;
        public readonly IUserRatingRepository UserRatingRepository;

        public UnitOfWork(
            DatabaseContext databaseContext,
            IApplicationUserRolesRepository applicationUserRolesRepository,
            IApplicationRolesRepository applicationRolesRepository,
            IApplicationUsersRepository applicationUsersRepository,
            IPersonsRepository personsRepository,
            IPropertyTypeRepository propertyTypeRepository,
            IPropertyRepository propertyRepository,
            IPropertyRatingRepository propertyRatingRepository,
            IPhotoRepository photoRepository,
            IPropertyReservationRepository propertyReservationRepository,
            IConversationRepository conversationRepository,
            IMessageRepository messageRepository,
            INotificationRepository notificationRepository,
            ICityRepository cityRepository,
            ICountryRepository countryRepository,
            IPaymentRepository paymentRepository,
            IReservationNotificationRepository reservationNotificationRepository,
            IUserRatingRepository userRatingRepository)
        {
            _databaseContext = databaseContext;
            ApplicationUserRolesRepository = applicationUserRolesRepository;
            ApplicationRolesRepository = applicationRolesRepository;
            ApplicationUsersRepository = applicationUsersRepository;
            PersonsRepository = personsRepository;
            PropertyTypeRepository = propertyTypeRepository;
            PropertyRepository = propertyRepository;
            PropertyRatingRepository = propertyRatingRepository;
            PhotoRepository = photoRepository;
            PropertyReservationRepository = propertyReservationRepository;
            ConversationRepository = conversationRepository;
            MessageRepository = messageRepository;
            NotificationRepository = notificationRepository;
            CityRepository = cityRepository;
            CountryRepository = countryRepository;
            PaymentRepository = paymentRepository;
            ReservationNotificationRepository = reservationNotificationRepository;
            UserRatingRepository = userRatingRepository;
        }
        public async Task<int> Execute(Action action)
        {
            using (BeginTransaction())
            {
                try
                {
                    action();

                    var affectedRows = await SaveChangesAsync();
                    await CommitTransactionAsync();
                    return affectedRows;
                }
                catch
                {
                    await RollbackTransactionAsync();
                    throw;
                }
            }
        }

        public async Task<int> ExecuteAsync(Func<Task> action)
        {
            using (var transaction = BeginTransaction())
            {
                try
                {
                    await action();

                    var affectedRows = await SaveChangesAsync();
                    await transaction.CommitAsync();
                    return affectedRows;
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
        }

        public DatabaseContext GetDatabaseContext()
        {
            return _databaseContext;
        }

        public IDbContextTransaction BeginTransaction()
        {
            return _databaseContext.Database.BeginTransaction();
        }

        public Task CommitTransactionAsync()
        {
            return _databaseContext.Database.CommitTransactionAsync();
        }

        public Task RollbackTransactionAsync()
        {
            return _databaseContext.Database.RollbackTransactionAsync();
        }

        public int SaveChanges()
        {
            return _databaseContext.SaveChanges();
        }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = new CancellationToken())
        {
            return _databaseContext.SaveChangesAsync(cancellationToken);
        }
    }
}
