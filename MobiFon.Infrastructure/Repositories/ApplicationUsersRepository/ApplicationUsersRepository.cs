using AutoMapper;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Entities.Identity;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.ApplicationUsersRepository
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

        public async Task<ApplicationUserDto> GetByIdAsync(int id)
        {
            ApplicationUserDto user = await ProjectToFirstOrDefaultAsync<ApplicationUserDto>(DatabaseContext.Users.Where(x => !x.IsDeleted && x.Id == id));
            user.Person.GenderName = user.Person.Gender.ToString();
            user.Person.MarriageStatusName = user.Person.MarriageStatus.ToString();
            user.Person.PositionName = user.Person.Position.ToString();
            return user;
        }

        public async Task<List<ApplicationUserDto>> GetClients()
        {
            return await ProjectToListAsync<ApplicationUserDto>(DatabaseContext.Users.Where(u => u.Active && u.IsClient));
        }

        public async Task<List<ApplicationUserDto>> GetEmployees()
        {
            var employees = await ProjectToListAsync<ApplicationUserDto>(DatabaseContext.Users.Where(x => x.IsEmployee == true && x.IsDeleted == false && x.Active == true));
            foreach (var item in employees)
            {
                item.Person.PositionName = item.Person.Position.ToString();
            }
            return employees;
        }
    }
}
