using MobiFon.Core.Dto.ApplicationRole;
using MobiFon.Infrastructure;
using MobiFon.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.ApplicationRolesService
{
    public class ApplicationRolesService : IApplicationRolesService
    {
        public readonly UnitOfWork _unitOfWork;

        public ApplicationRolesService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
        }

        public Task AddRangeAsync(IEnumerable<ApplicationRoleDto> entitiesDto)
        {
            return _unitOfWork.ApplicationUserRolesRepository.AddRangeAsync(entitiesDto);
        }

        public async Task<ApplicationRoleDto> AddAsync(ApplicationRoleDto roleDto)
        {
            roleDto = await _unitOfWork.ApplicationRolesRepository.AddAsync(roleDto);
            await _unitOfWork.SaveChangesAsync();
            return roleDto;
        }

        public async Task<List<ApplicationRoleDto>> GetAllAsync()
        {
            throw new NotImplementedException();

        }
        public Task<ApplicationRoleDto> GetByIdAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<ApplicationRoleDto> GetByRoleLevelIdOrName(int roleLeveleId, string roleName)
        {
            return _unitOfWork.ApplicationRolesRepository.GetByRoleLevelOrName(roleLeveleId, roleName);
        }

        public Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            return _unitOfWork.ApplicationUserRolesRepository.RemoveByIdAsync(id);
        }

        public void Update(ApplicationRoleDto entity)
        {
            throw new NotImplementedException();
        }
        public void UpdateRange(IEnumerable<ApplicationRoleDto> entitiesDto)
        {
            _unitOfWork.ApplicationUserRolesRepository.UpdateRange(entitiesDto);
        }
    }
}
