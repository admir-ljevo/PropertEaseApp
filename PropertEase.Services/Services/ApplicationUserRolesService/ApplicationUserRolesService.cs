using PropertEase.Core.Dto;
using PropertEase.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.ApplicationUserRolesService
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
        public async Task<ApplicationUserRoleDto> AddAsync(ApplicationUserRoleDto entity)
        {
            await _unitOfWork.ApplicationUserRolesRepository.AddUserRoleAsync(entity.UserId, entity.RoleId);
            return entity;
        }

        public Task<IEnumerable<ApplicationUserRoleDto>> GetByUserId(int userId)
        {
            return _unitOfWork.ApplicationUserRolesRepository.GetByUserId(userId);
        }

        public Task AssignRoleAsync(int userId, int roleId)
        {
            return _unitOfWork.ApplicationUserRolesRepository.AddUserRoleAsync(userId, roleId);
        }

        public Task RemoveRoleAsync(int userId, int roleId)
        {
            return _unitOfWork.ApplicationUserRolesRepository.RemoveUserRoleByUserAndRoleAsync(userId, roleId);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await _unitOfWork.ApplicationUserRolesRepository.RemoveUserRoleAsync(id);
        }

        public void UpdateRange(IEnumerable<ApplicationUserRoleDto> entitiesDto)
        {
            _unitOfWork.ApplicationUserRolesRepository.UpdateRange(entitiesDto);
        }
    }
}
