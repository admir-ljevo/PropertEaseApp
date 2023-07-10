using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities.Base
{
    public interface IBaseEntity
    {
       int Id { get; set; }
       bool IsDeleted { get; set; }
       DateTime CreatedAt { get; set; }
       DateTime? ModifiedAt { get; set;}
    }
}
