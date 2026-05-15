using PropertEase.Core.Dto.ApplicationRole;
using PropertEase.Infrastructure;
using PropertEase.Infrastructure.UnitOfWork;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.ApplicationRolesService
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
            return await _unitOfWork.ApplicationRolesRepository.GetAllAsync();

        }
        public Task<ApplicationRoleDto> GetByRoleLevelIdOrName(int roleLeveleId, string roleName)
        {
            return _unitOfWork.ApplicationRolesRepository.GetByRoleLevelOrName(roleLeveleId, roleName);
        }

        public async Task<ApplicationRoleDto> UpdateAsync(ApplicationRoleDto dto)
        {
            var db = _unitOfWork.GetDatabaseContext();
            var role = await db.Roles.FindAsync(dto.Id)
                ?? throw new KeyNotFoundException($"Role {dto.Id} not found.");
            role.Name = dto.Name;
            role.NormalizedName = dto.Name?.ToUpperInvariant();
            role.RoleLevel = dto.RoleLevel;
            await db.SaveChangesAsync();
            return dto;
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var db = _unitOfWork.GetDatabaseContext();

            if (db.UserRoles.Any(ur => ur.RoleId == id))
                throw new InvalidOperationException("Cannot delete a role that is assigned to one or more users.");

            await _unitOfWork.ApplicationRolesRepository.RemoveByIdAsync(id);
        }

        public void UpdateRange(IEnumerable<ApplicationRoleDto> entitiesDto)
        {
            _unitOfWork.ApplicationUserRolesRepository.UpdateRange(entitiesDto);
        }
    }
}
