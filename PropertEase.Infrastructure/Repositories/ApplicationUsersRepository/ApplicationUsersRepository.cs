using AutoMapper;
using Microsoft.EntityFrameworkCore;
using PropertEase.Core.Dto.ApplicationUser;
using PropertEase.Core.Entities.Identity;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using PropertEase.Core.Filters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.ApplicationUsersRepository
{
    public class ApplicationUsersRepository : BaseRepository<ApplicationUser, int>, IApplicationUsersRepository
    {
        public ApplicationUsersRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string UserName)
        {
            return await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(DatabaseContext.Users.Where(c => (c.UserName == UserName || c.Email == UserName) && c.Active == true));
        }
        public async Task<List<ApplicationUserDto>> GetAllAsync()
        {
            return await ProjectToListAsync<ApplicationUserDto>(DatabaseContext.Users.Where(u => !u.IsDeleted));
        }
        public async Task<ApplicationUserDto> GetByIdAsync(int id)
        {
            ApplicationUserDto user = await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(DatabaseContext.Users.Where(x => !x.IsDeleted && x.Id == id));
            user.Person.GenderName = user.Person.Gender.ToString();
            user.Person.MarriageStatusName = user.Person.MarriageStatus.ToString();
            return user;
        }

        public async Task<List<ApplicationUserDto>> GetClients()
        {
            return await ProjectToListAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(u =>
                    u.Active && !u.IsDeleted &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Client")));
        }

        public async Task<List<ApplicationUserDto>> GetEmployees()
        {
            return await ProjectToListAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(u =>
                    u.Active && !u.IsDeleted &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Renter")));
        }

        public async Task<PropertEase.Core.Dto.PagedResult<ApplicationUserDto>> GetFiltered(UserFilter filter)
        {
            var query = DatabaseContext.Users.Where(u =>
                (string.IsNullOrEmpty(filter.SearchField) || u.UserName.Contains(filter.SearchField) || u.Email.Contains(filter.SearchField))
                && (filter.CityId == u.Person.PlaceOfResidenceId || !filter.CityId.HasValue)
                && (string.IsNullOrEmpty(filter.Role) || u.Roles.First().Role.Name.Contains(filter.Role))
                && !u.IsDeleted);

            var totalCount = await query.CountAsync();
            var items = await ProjectToListAsync<ApplicationUserDto>(
                query.Skip((filter.Page - 1) * filter.PageSize).Take(filter.PageSize));

            return new PropertEase.Core.Dto.PagedResult<ApplicationUserDto> { Items = items, TotalCount = totalCount };
        }

        public async Task<List<ApplicationUserDto>> GetRenters()
        {
            return await ProjectToListAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(u =>
                    !u.IsDeleted && u.Active &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Renter")));
        }

        public async Task<List<ApplicationUserDto>> GetAdminsAsync()
        {
            return await ProjectToListAsync<ApplicationUserDto>(
                DatabaseContext.Users.Where(u =>
                    !u.IsDeleted && u.Active &&
                    u.Roles.Any(r => !r.IsDeleted && r.Role.Name == "Admin")));
        }
    }
}
