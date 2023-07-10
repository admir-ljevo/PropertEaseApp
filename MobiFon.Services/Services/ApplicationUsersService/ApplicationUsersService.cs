﻿using Microsoft.AspNetCore.Identity;
using MobiFon.Core.Dto;
using MobiFon.Core.Dto.ApplicationUser;
using MobiFon.Core.Dto.Person;
using MobiFon.Core.Entities.Identity;
using MobiFon.Core.Enumerations;
using MobiFon.Infrastructure.Repositories.ApplicationRolesRepository;
using MobiFon.Infrastructure.Repositories.ApplicationUserRolesRepository;
using MobiFon.Infrastructure.UnitOfWork;
using MobiFon.Shared.Services.Crypto;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using System.Globalization;

namespace MobiFon.Services.Services.ApplicationUsersService
{
    public class ApplicationUsersService : IApplicationUsersService
    {
        private readonly UnitOfWork _unitOfWork;
        private readonly IApplicationUserRolesRepository _applicationUserRolesRepository;
        private readonly IApplicationRolesRepository _applicationRolesRepository;
        private readonly ICrypto _crypto;
        private readonly IPasswordHasher<ApplicationUser> _passwordHasher;

        public ApplicationUsersService(IUnitOfWork unitOfWork, IApplicationUserRolesRepository applicationUserRolesRepository, IApplicationRolesRepository applicationRolesRepository, ICrypto crypto, IPasswordHasher<ApplicationUser> passwordHasher)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
            _applicationUserRolesRepository = applicationUserRolesRepository;
            _applicationRolesRepository = applicationRolesRepository;
            _crypto = crypto;
            _passwordHasher = passwordHasher;
        }
        public async Task<ApplicationUserDto> AddAsync(ApplicationUserDto entityDto)
        {
            var user = await _unitOfWork.ApplicationUsersRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            return user;
        }

        public async Task<ApplicationUserDto> AddClientAsync(ClientInsertDto user)
        {
            var newUser = new ApplicationUserDto();
            newUser.Person = new PersonDto
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Address = user.Address,
                BirthDate = user.BirthDate,
                MarriageStatus = user.MarriageStatus,
                PostCode = user.PostCode,
                Gender = user.Gender,
                Biography = "",
            };
            newUser.Active = true;
            newUser.Email = user.Email;
            newUser.NormalizedEmail = user.Email.ToUpper();
            newUser.UserName = user.UserName;
            newUser.NormalizedUserName = user.UserName.ToUpper();
            newUser.PhoneNumber = user.PhoneNumber;
            newUser.EmailConfirmed = true;
            newUser.ConcurrencyStamp = Guid.NewGuid().ToString();
            newUser.PasswordHash = _passwordHasher.HashPassword(new ApplicationUser(), user.Password);
            newUser.IsClient = true;
            
            newUser = await _unitOfWork.ApplicationUsersRepository.AddAsync(newUser);
            await _unitOfWork.SaveChangesAsync();

            var role = await _applicationRolesRepository.GetByRoleLevelOrName((int)Role.Employee, Role.Employee.ToString());
            await _applicationUserRolesRepository.AddAsync(new ApplicationUserRoleDto
            {
                UserId = newUser.Id,
                RoleId = role.Id
            });
            await _unitOfWork.SaveChangesAsync();

            return newUser;


        }

        public async Task<ApplicationUserDto> AddEmployeeAsync(EmployeeInsertDto user)
        {
            var newUser = new ApplicationUserDto();
            newUser.Person = new PersonDto
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                MarriageStatus = user.MarriageStatus,
                Citizenship = user.Citizenship,
                Biography = user.Biography,
                MembershipCard = false,
                BirthDate = user.BirthDate,
                Address = user.Address,
                PostCode = user.PostCode,
                BirthPlaceId = user.BirthPlaceId,
                DateOfEmployment = user.DateOfEmployment,
                Gender = user.Gender,
                JMBG = user.Jmbg,
                Nationality = user.Nationality,
                Pay = user.Pay,
                PlaceOfResidenceId = user.PlaceOfResidenceId,
                Position = user.Position,
                ProfilePhoto = user.ProfilePhoto,
                ProfilePhotoThumbnail = user.ProfilePhoto,
                Qualifications = user.Qualifications,
                WorkExperience = user.WorkExperience
            };

            var passwd = _crypto.GeneratePassword();
            newUser.Active = true;
            newUser.Email = user.Email;
            newUser.NormalizedEmail = user.Email.ToUpper();
            newUser.UserName = user.UserName;
            newUser.NormalizedUserName = user.UserName.ToUpper();
            newUser.EmailConfirmed = true;
            newUser.PhoneNumber = user.PhoneNumber;
            newUser.ConcurrencyStamp = Guid.NewGuid().ToString();
            newUser.PasswordHash = _passwordHasher.HashPassword(new ApplicationUser(), passwd);
            newUser.IsEmployee = true;
            newUser = await _unitOfWork.ApplicationUsersRepository.AddAsync(newUser);
            await _unitOfWork.SaveChangesAsync();

            var role = await _applicationRolesRepository.GetByRoleLevelOrName((int)Role.Employee, Role.Employee.ToString());
            await _applicationUserRolesRepository.AddAsync(new ApplicationUserRoleDto
            {
                UserId = newUser.Id,
                RoleId = role.Id
            });
            await _unitOfWork.SaveChangesAsync();

           
            return newUser;
        }

        public async Task ChangePhoto(ApplicationUserDto entityDto)
        {
            _unitOfWork.PersonsRepository.Update(entityDto.Person);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<ApplicationUserDto> EditEmployee(EmployeeInsertDto user)
        {
            try
            {
                var editUser = await _unitOfWork.ApplicationUsersRepository.GetByIdAsync(user.Id);
                editUser.Person.FirstName = user.FirstName;
                editUser.Person.LastName = user.LastName;
                editUser.Person.MarriageStatus = user.MarriageStatus;
                editUser.Person.Citizenship = user.Citizenship;
                editUser.Person.Biography = user.Biography;
                editUser.Person.MembershipCard = false;
                editUser.Person.BirthDate = user.BirthDate;
                editUser.Person.Address = user.Address;
                editUser.Person.PostCode = user.PostCode;
                editUser.Person.BirthPlaceId = user.BirthPlaceId;
                editUser.Person.DateOfEmployment = user.DateOfEmployment;
                editUser.Person.Gender = user.Gender;
                editUser.Person.JMBG = user.Jmbg;
                editUser.Person.Nationality = user.Nationality;
                editUser.Person.Pay = user.Pay;
                editUser.Person.PlaceOfResidenceId = user.PlaceOfResidenceId;
                editUser.Person.Position = user.Position;
                editUser.Person.ProfilePhoto = user.ProfilePhoto;
                editUser.Person.ProfilePhotoThumbnail = user.ProfilePhoto;
                editUser.Person.Qualifications = user.Qualifications;
                editUser.Person.WorkExperience = user.WorkExperience;

                editUser.Person.PlaceOfResidence = null;
                editUser.Person.BirthPlace = null;
                if (editUser.Person.PlaceOfResidenceId == 0)
                {
                    editUser.Person.PlaceOfResidenceId = null;
                }
                if (editUser.Person.BirthPlaceId == 0)
                {
                    editUser.Person.BirthPlaceId = null;
                }
                _unitOfWork.PersonsRepository.Update(editUser.Person);

                editUser.Email = user.Email;
                editUser.NormalizedEmail = user.Email.ToUpper();
                editUser.UserName = user.UserName;
                editUser.NormalizedUserName = user.UserName.ToUpper();
                editUser.IsEmployee = true;
                editUser.PhoneNumber = user.PhoneNumber;
                editUser.UserRoles = null;
                editUser.Person = null;
                _unitOfWork.ApplicationUsersRepository.Update(editUser);
                await _unitOfWork.SaveChangesAsync();

                return editUser;
            }
            catch (Exception ex)
            {

                throw;
            }
        }

        public async Task<ApplicationUserDto> FindByUserNameOrEmailAsync(string pUserName)
        {
            return await _unitOfWork.ApplicationUsersRepository.FindByUserNameOrEmailAsync(pUserName);
        }

        public Task<List<ApplicationUserDto>> GetAllAsync()
        {
            throw new NotImplementedException();
        }

        public async Task<ApplicationUserDto> GetByIdAsync(int id)
        {
            return await _unitOfWork.ApplicationUsersRepository.GetByIdAsync(id);   
        }

        public async Task<List<ApplicationUserDto>> GetClients()
        {
            return await _unitOfWork.ApplicationUsersRepository.GetClients();
        }

        public async Task<List<ApplicationUserDto>> GetEmployees()
        {
            return await _unitOfWork.ApplicationUsersRepository.GetEmployees();
        }

        public Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            throw new NotImplementedException();
        }

        public void Update(ApplicationUserDto entity)
        {
            throw new NotImplementedException();
        }

        public async Task<ApplicationUserDto> UpdateAsync(ApplicationUserDto entityDto)
        {
            var result = await _unitOfWork.ExecuteAsync(async () =>
            {
                _unitOfWork.ApplicationUsersRepository.Update(entityDto);
            });

            return entityDto;
        }
    }
}
