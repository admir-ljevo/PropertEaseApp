using PropertEase.Core.Dto.Country;
using PropertEase.Infrastructure.UnitOfWork;

namespace PropertEase.Services.Services.CountryService
{
    public class CountryService : ICountryService
    {
        private readonly UnitOfWork _unitOfWork;

        public CountryService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = (UnitOfWork)unitOfWork;
        }

        public async Task<CountryDto> AddAsync(CountryDto entityDto)
        {
            await _unitOfWork.CountryRepository.AddAsync(entityDto);
            await _unitOfWork.SaveChangesAsync();
            return entityDto;
        }

        public async Task<List<CountryDto>> GetAllAsync()
        {
            return await _unitOfWork.CountryRepository.GetAllAsync();
        }

        public async Task<CountryDto> GetByIdAsync(int id)
        {
            return await _unitOfWork.CountryRepository.GetByIdAsync(id);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            await _unitOfWork.CountryRepository.RemoveByIdAsync(id, isSoft);
            await _unitOfWork.SaveChangesAsync();
        }

        public void Update(CountryDto entity)
        {
            _unitOfWork.CountryRepository.Update(entity);
            _unitOfWork.SaveChanges();
        }

        public async Task<CountryDto> UpdateAsync(CountryDto entity)
        {
            _unitOfWork.CountryRepository.Update(entity);
            await _unitOfWork.SaveChangesAsync();
            return entity;
        }
    }
}
