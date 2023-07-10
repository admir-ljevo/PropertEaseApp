using MobiFon.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Entities
{
    public class Photo: BaseEntity
    {
        public string Url { get; set; }
        public Property? Property { get; set; }
        public int? PropertyId { get; set; }

    }
}
