using PropertEase.Core.Dto;

namespace PropertEase.Services.EnumManager
{
    public interface IEnumManager
    {
        List<EntityItemDto> Genders();
        List<EntityItemDto> Positions();
        List<EntityItemDto> MarriageStatuses();
    }
}
