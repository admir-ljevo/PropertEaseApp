using PropertEase.Core.Dto.Property;
using PropertEase.Core.Enumerations;
using PropertEase.Core.Filters;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Services.Recommendations;
using PropertEase.Services.Services.BaseService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.PropertyService
{
    public class PropertyService : IPropertyService
    {
        private readonly UnitOfWork unitOfWork;
        private readonly IRecommendationEngine _recommendationEngine;

        public PropertyService(IUnitOfWork unitOfWork, IRecommendationEngine recommendationEngine)
        {
            this.unitOfWork = (UnitOfWork)unitOfWork;
            _recommendationEngine = recommendationEngine;
        }

        public async Task<PropertyDto> AddAsync(PropertyDto entityDto)
        {
            var insertedDto = await unitOfWork.PropertyRepository.AddAsync(entityDto);
            await unitOfWork.SaveChangesAsync();
            return insertedDto;
        }

        public async Task<List<PropertyDto>> GetAllAsync()
        {
            return await unitOfWork.PropertyRepository.GetAllAsync();   
        }

        public async Task<PropertyDto> GetByIdAsync(int id)
        {
            return await unitOfWork.PropertyRepository.GetByIdAsync(id);
        }

        public async Task<List<PropertyDto>> GetByNameAsync(string name)
        {
            return await unitOfWork.PropertyRepository.GetByName(name);
        }

        public async Task<PropertEase.Core.Dto.PagedResult<PropertyListDto>> GetFilteredData(PropertyFilter filter)
        {
            return await unitOfWork.PropertyRepository.GetFilteredData(filter);
        }

        public async Task RemoveByIdAsync(int id, bool isSoft = true)
        {
            var db = unitOfWork.GetDatabaseContext();

            var hasActiveReservations = db.PropertyReservations.Any(r =>
                r.PropertyId == id && !r.IsDeleted &&
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.Paid));
            if (hasActiveReservations)
                throw new InvalidOperationException("Cannot delete a property that has active or pending reservations.");

            // cascade: Messages → Conversations 
            var conversationIds = db.Conversations
                .Where(c => c.PropertyId == id && !c.IsDeleted)
                .Select(c => c.Id).ToList();
            SoftDeleteRange(db.Messages.Where(m => conversationIds.Contains(m.ConversationId) && !m.IsDeleted));
            SoftDeleteRange(db.Conversations.Where(c => conversationIds.Contains(c.Id) && !c.IsDeleted));

            SoftDeleteRange(db.PropertyRatings.Where(r => r.PropertyId == id && !r.IsDeleted));
            SoftDeleteRange(db.Photos.Where(p => p.PropertyId == id && !p.IsDeleted));

            // completed/cancelled reservations and their payments and ratings are preserved for history

            var property = await db.Properties.FindAsync(id);
            if (property != null) property.IsDeleted = true;

            await unitOfWork.SaveChangesAsync();
        }

        private static void SoftDeleteRange<T>(IQueryable<T> query) where T : PropertEase.Core.Entities.Base.BaseEntity
        {
            foreach (var e in query.ToList()) e.IsDeleted = true;
        }

        public void Update(PropertyDto entity)
        {
            unitOfWork.PropertyRepository.Update(entity);
            unitOfWork.SaveChanges();
        }
        public async Task<PropertyDto> UpdateAsync(PropertyDto property)
        {
            unitOfWork.PropertyRepository.Update(property);
            await unitOfWork.SaveChangesAsync();
            return property;
        }

        public async Task<List<PropertyRecommendationDto>> GetRecommendedPropertiesAsync(int propertyId)
        {
            var recommended = await _recommendationEngine.GetRecommendationsByPropertyAsync(propertyId);
            if (recommended.Count == 0) return new List<PropertyRecommendationDto>();

            var ids = recommended.Select(r => r.PropertyId).ToList();
            var properties = await unitOfWork.PropertyRepository.GetByIdsAsync(ids);

            var confidenceMap = recommended.ToDictionary(r => r.PropertyId, r => r.Confidence);
            foreach (var prop in properties)
            {
                if (confidenceMap.TryGetValue(prop.Id, out var conf))
                {
                    var pct = (int)Math.Round(conf * 100);
                    prop.Reason = $"{pct}% korisnika koji su rezervirali ovu nekretninu rezerviralo je i ovu";
                }
            }
            return properties;
        }
    }
}
