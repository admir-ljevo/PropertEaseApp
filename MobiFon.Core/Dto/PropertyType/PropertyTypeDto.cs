using MobiFon.Core.Dto.Property;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.PropertyType
{
    public class PropertyTypeDto: BaseDto
    {
        public string Name { get; set; }
        public IEnumerable<PropertyDto> Properties { get; set; }    
    }
}
