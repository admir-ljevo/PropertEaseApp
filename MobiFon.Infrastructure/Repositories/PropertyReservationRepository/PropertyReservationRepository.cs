using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.EntityFrameworkCore;
using MobiFon.Core.Dto;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyReservation;
using MobiFon.Core.Entities;
using MobiFon.Core.SearchObjects;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using PropertEase.Core.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyReservationRepository
{
    public class PropertyReservationRepository : BaseRepository<PropertyReservation, int>, IPropertyReservationRepository
    {
        public PropertyReservationRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyReservationDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => pr.Id == id && !pr.IsDeleted));
        }

        public Task<List<PropertyReservationDto>> GetByNameAsync(string name)
        {
            throw new NotImplementedException();
        }

        public async Task<List<PropertyReservationDto>> GetForPaginationAsync(string searchFilter, int pageSize, int offset)
        {
            return await ProjectToListAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => !pr.IsDeleted).Skip(offset).Take(pageSize));
        }

        public async Task<List<PropertyReservationDto>> GetAllAsync()
        {
            return await ProjectToListAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(pr => !pr.IsDeleted));
        }
        public async Task<List<PropertyReservationDto>> GetFiltered(PropertyReservationFilter filter)
        {
            var reservationsQuery = DatabaseContext.PropertyReservations
                .Where(pr =>
                    (!filter.DateOccupancyStartedStart.HasValue || pr.DateOfOccupancyStart >= filter.DateOccupancyStartedStart.Value) &&
                    (!filter.DateOccupancyStartedEnd.HasValue || pr.DateOfOccupancyStart <= filter.DateOccupancyStartedEnd.Value) &&
                    (!filter.DateOccupancyEnded.HasValue || pr.DateOfOccupancyEnd <= filter.DateOccupancyEnded.Value) &&
                    (!filter.totalPriceFrom.HasValue || pr.TotalPrice >= filter.totalPriceFrom.Value) &&
                    (!filter.totalPriceTo.HasValue || pr.TotalPrice <= filter.totalPriceTo.Value) &&
                    (!filter.clientId.HasValue || pr.ClientId == filter.clientId) &&
                    (!filter.propertyId.HasValue || pr.PropertyId == filter.propertyId) &&
                    (!filter.renterId.HasValue || pr.RenterId == filter.renterId) &&
                    (!filter.isActive.HasValue || pr.IsActive == filter.isActive.Value) 
                    &&(filter.propertyTypeId == null || filter.propertyTypeId == pr.Property.PropertyTypeId) &&
                    !pr.IsDeleted);
            reservationsQuery = reservationsQuery.Include(pr => pr.Client.Person);
            reservationsQuery = reservationsQuery.Include(pr => pr.Renter.Person);
            if (!string.IsNullOrEmpty(filter.propertyName))
            {
                reservationsQuery = reservationsQuery.Where(pr => pr.Property.Name.Contains(filter.propertyName));
            }

            var reservations = await reservationsQuery
                .Include(pr => pr.Property) 
                .OrderBy(pr => pr.DateOfOccupancyStart)
                .ToListAsync();

            foreach (var reservation in reservations)
            {
                await DatabaseContext.Entry(reservation.Property).Reference(p => p.City).LoadAsync();
                await DatabaseContext.Entry(reservation.Property).Reference(p => p.PropertyType).LoadAsync();

            }

            var reservationsDto = reservations.Select(pr => new PropertyReservationDto
            {
                Client = new ApplicationUserDto
                {
                    Person = new PersonDto
                    {
                        FirstName = pr.Client.Person.FirstName,
                        LastName = pr.Client.Person.LastName,
                    }
                },
                Renter = new ApplicationUserDto
                {
                    Person = new PersonDto
                    {
                        FirstName = pr.Renter.Person.FirstName,
                        LastName = pr.Renter.Person.LastName,
                    }
                },
                Property = new PropertyDto
                {
                    Id = pr.PropertyId,
                    Name = pr.Property.Name,
                    City = new Core.Dto.City.CityDto
                    {
                        Id = pr.Property.City.Id, 
                        Name = pr.Property.City.Name,
                        CountryId = pr.Property.City.CountryId, 
                        
                    },
                    PropertyTypeId = pr.Property.PropertyTypeId,
                    PropertyType = new Core.Dto.PropertyType.PropertyTypeDto
                    {
                        Id=pr.Property.PropertyType.Id,
                        Name = pr.Property.PropertyType.Name,
                    }
                    // ...
                },
                ReservationNumber = pr.ReservationNumber,
                Description = pr.Description,
                PropertyId = pr.PropertyId,
                RenterId = pr.RenterId,
                ClientId = pr.ClientId,
                NumberOfGuests = pr.NumberOfGuests,
                DateOfOccupancyStart = pr.DateOfOccupancyStart,
                DateOfOccupancyEnd = pr.DateOfOccupancyEnd,
                NumberOfDays = pr.NumberOfDays,
                NumberOfMonths = pr.NumberOfMonths,
                TotalPrice = pr.TotalPrice,
                IsMonthly = pr.IsMonthly,
                IsDaily = pr.IsDaily,
                IsActive = pr.IsActive
            }).ToList();

            return reservationsDto;
        }






        public async new Task<List<PropertyReservationDto>> GetRenterBusinessReportData(ReportSearchObject search)
        {
            var result = await ProjectToListAsync<PropertyReservationDto>(DatabaseContext.PropertyReservations.Where(
                x => !x.IsDeleted && search.DateFrom <= x.CreatedAt && search.DateTo >= x.CreatedAt && search.RenterId == x.RenterId));
            return result;
        }
    }
}
