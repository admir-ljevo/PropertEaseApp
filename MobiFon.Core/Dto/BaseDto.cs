using MobiFon.Core.Entities.Base;

namespace MobiFon.Core.Dto
{
    public class BaseDto: IBaseEntity
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public int TotalRecordsCount { get; set; }
        public bool IsDeleted { get; set; }
    }
}
