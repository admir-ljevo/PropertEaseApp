using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities.Base
{
    public class BaseEntity: IBaseEntity
    {
       public int Id { get; set; }
       public bool IsDeleted { get; set; }
       public DateTime CreatedAt { get; set; }
       public DateTime? ModifiedAt { get; set; }
    }
}
