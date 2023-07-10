using MobiFon.Core.Dto;
using MobiFon.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.ApplicationUserRolesService
{
    public class ApplicationUserRolesService : IApplicationUserRolesService
    {
        public readonly UnitOfWork _unitOfWork;

        public ApplicationUserRolesService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
        }

        public Task AddRangeAsync(IEnumerable<ApplicationUserRoleDto> entitiesDto)
        {
            return _unitOfWork.ApplicationUserRolesRepository.AddRangeAsync(entitiesDto);
        }

        public Task<ApplicationUserRoleDto> AddAsync(ApplicationUserRoleDto country)
        {
            throw new NotImplementedException();
        }

        public Task<List<ApplicationUserRoleDto>> GetAllAsync()
        {
            throw new NotImplementedException();
        }

        public Task<ApplicationUserRoleDto> GetByIdAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int pUserId)
        {
            return _unitOfWork.ApplicationUserRolesRepository.GetByUserId(pUserId);
        }

        public Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            return _unitOfWork.ApplicationUserRolesRepository.RemoveByIdAsync(id);
        }

        public void Update(ApplicationUserRoleDto entity)
        {
            throw new NotImplementedException();
        }
        public void UpdateRange(IEnumerable<ApplicationUserRoleDto> entitiesDto)
        {
            _unitOfWork.ApplicationUserRolesRepository.UpdateRange(entitiesDto);
        }
    }
}
