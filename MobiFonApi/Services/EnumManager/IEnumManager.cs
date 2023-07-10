using MobiFon.Core.Dto;

namespace MobiFon.Services.EnumManager
{
    public interface IEnumManager
    {
        List<EntityItemDto> Genders();
        List<EntityItemDto> Positions();
        List<EntityItemDto> MarriageStatuses();
    }
}
