using MobiFon.Core.Dto;
using MobiFon.Core.Enumerations;

namespace MobiFon.Services.EnumManager
{
    public class EnumManager : IEnumManager
    {

        public EnumManager()
        {

        }

        public List<EntityItemDto> Genders()
        {
            var genders = Enum.GetValues(typeof(Gender)).Cast<Gender>().ToList();
            var genderItems = new List<EntityItemDto>();
            genderItems = genders.Select(x => new EntityItemDto { Id = (int)x, Label = x.ToString() }).ToList();

            return genderItems;
        }
        public List<EntityItemDto> Positions()
        {
            var positions = Enum.GetValues(typeof(Position)).Cast<Position>().ToList();
            var positionItems = new List<EntityItemDto>();
            positionItems = positions.Select(x => new EntityItemDto { Id = (int)x, Label = x.ToString() }).ToList();

            return positionItems;
        }

        public List<EntityItemDto> MarriageStatuses()
        {
            var marriageStatuses = Enum.GetValues(typeof(MarriageStatus)).Cast<MarriageStatus>().ToList();
            var marriageStatusItems = new List<EntityItemDto>();
            marriageStatusItems = marriageStatuses.Select(x => new EntityItemDto { Id = (int)x, Label = x.ToString() }).ToList();

            return marriageStatusItems;
        }
    }
}
