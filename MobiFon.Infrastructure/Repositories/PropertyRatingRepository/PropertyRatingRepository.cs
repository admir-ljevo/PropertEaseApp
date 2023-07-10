using AutoMapper;
using Microsoft.EntityFrameworkCore;
using MobiFon.Core.Dto.Property;
using MobiFon.Core.Dto.PropertyRating;
using MobiFon.Core.Entities;
using MobiFon.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Infrastructure.Repositories.PropertyRatingRepository
{
    public class PropertyRatingRepository : BaseRepository<PropertyRating, int>, IPropertyRatingRepository
    {
        public PropertyRatingRepository(IMapper mapper, DatabaseContext databaseContext) : base(mapper, databaseContext)
        {
        }

        public async Task<PropertyRatingDto> GetByIdAsync(int id)
        {
            return await ProjectToFirstOrDefaultAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr => pr.Id == id));
        }

        public async Task<List<PropertyRatingDto>> GetByName(string name)
        {
            return await ProjectToListAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr => pr.Property.Name == name));
        }

       public async Task<List<PropertyRatingDto>> GetAllAsync()
       {
            var propertyRatings = await ProjectToListAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr => !pr.IsDeleted));
            return propertyRatings;
       }

        public async Task<List<PropertyRatingDto>> GetByPropertyId(int id)
        {
            return await ProjectToListAsync<PropertyRatingDto>(DatabaseContext.PropertyRatings.Where(pr=>pr.PropertyId == id && !pr.IsDeleted));
        }
    }
}
