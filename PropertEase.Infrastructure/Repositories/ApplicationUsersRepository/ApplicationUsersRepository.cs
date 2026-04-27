using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto;
using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Dto.City;
using PropertEase.Core.Dto.Person;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;

namespace PropertEase.Infrastructure.Repositories.ApplicationUsersRepository
{
    public class ApplicationUsersRepository : BaseRepository<ApplicationUser, int>, IApplicationUsersRepository
    {
        public ApplicationUsersRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string UserName)
        {
            return await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(c => (c.UserName == UserName || c.Email == UserName) && c.Active == true));
        }

        public async Task<List<ApplicationUserDto>> GetAllAsync()
        {
            return await DatabaseContext.Users
                .AsNoTracking()
                .Where(u => !u.IsDeleted)
                .Take(100)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                        ProfilePhotoThumbnail = u.Person.ProfilePhotoThumbnail,
                    }
                })
                .ToListAsync();
        }

        public async Task<ApplicationUserDto> GetByIdAsync(int id)
        {
            ApplicationUserDto user = await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(x => !x.IsDeleted && x.Id == id));
            user.Person.GenderName = user.Person.Gender.ToString();
            user.Person.MarriageStatusName = user.Person.MarriageStatus.ToString();
            return user;
        }

        public async Task<List<ApplicationUserDto>> GetClients()
        {
            return await DatabaseContext.Users
                .AsNoTracking()
                .Where(u => u.Active && !u.IsDeleted &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Client"))
                .Take(100)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                        ProfilePhotoThumbnail = u.Person.ProfilePhotoThumbnail,
                    }
                })
                .ToListAsync();
        }

        public async Task<List<ApplicationUserDto>> GetEmployees()
        {
            return await DatabaseContext.Users
                .AsNoTracking()
                .Where(u => u.Active && !u.IsDeleted &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Renter"))
                .Take(100)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                        ProfilePhotoThumbnail = u.Person.ProfilePhotoThumbnail,
                    }
                })
                .ToListAsync();
        }

        public async Task<PropertEase.Core.Dto.PagedResult<ApplicationUserDto>> GetFiltered(UserFilter filter)
        {
            var pageSize = Math.Min(filter.PageSize, 100);
            var query = DatabaseContext.Users
                .AsNoTracking()
                .Where(u =>
                    (string.IsNullOrEmpty(filter.SearchField) ||
                        u.UserName.Contains(filter.SearchField) || u.Email.Contains(filter.SearchField)) &&
                    (filter.CityId == u.Person.PlaceOfResidenceId || !filter.CityId.HasValue) &&
                    (string.IsNullOrEmpty(filter.Role) || u.Roles.First().Role.Name.Contains(filter.Role)) &&
                    !u.IsDeleted);

            var totalCount = await query.CountAsync();
            var items = await query
                .Skip((filter.Page - 1) * pageSize)
                .Take(pageSize)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    PhoneNumber = u.PhoneNumber,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                        ProfilePhotoThumbnail = u.Person.ProfilePhotoThumbnail,
                        Address = u.Person.Address,
                        BirthDate = u.Person.BirthDate,
                        JMBG = u.Person.JMBG,
                        Gender = u.Person.Gender,
                        Nationality = u.Person.Nationality,
                        Citizenship = u.Person.Citizenship,
                        PlaceOfResidenceId = u.Person.PlaceOfResidenceId,
                        PlaceOfResidence = u.Person.PlaceOfResidence == null ? null : new CityDto
                        {
                            Id = u.Person.PlaceOfResidence.Id,
                            Name = u.Person.PlaceOfResidence.Name,
                        },
                    },
                    UserRoles = u.Roles.Select(r => new ApplicationUserRoleDto
                    {
                        UserId = u.Id,
                        RoleId = r.RoleId,
                        Role = new ApplicationRoleDto { Name = r.Role.Name },
                    }).ToList(),
                })
                .ToListAsync();

            return new PropertEase.Core.Dto.PagedResult<ApplicationUserDto> { Items = items, TotalCount = totalCount };
        }

        public async Task<List<ApplicationUserDto>> GetRenters()
        {
            return await DatabaseContext.Users
                .AsNoTracking()
                .Where(u => !u.IsDeleted && u.Active &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Renter"))
                .Take(100)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                        ProfilePhotoThumbnail = u.Person.ProfilePhotoThumbnail,
                    }
                })
                .ToListAsync();
        }

        public async Task<List<ApplicationUserDto>> GetAdminsAsync()
        {
            return await DatabaseContext.Users
                .AsNoTracking()
                .Where(u => !u.IsDeleted && u.Active &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Admin"))
                .Take(100)
                .Select(u => new ApplicationUserDto
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    Email = u.Email,
                    Active = u.Active,
                    IsDeleted = u.IsDeleted,
                    PersonId = u.Person != null ? u.Person.Id : 0,
                    Person = u.Person == null ? null : new PersonDto
                    {
                        Id = u.Person.Id,
                        FirstName = u.Person.FirstName,
                        LastName = u.Person.LastName,
                        ProfilePhoto = u.Person.ProfilePhoto,
                    }
                })
                .ToListAsync();
        }
    }
}
