using PropertEase.Core.Dto.Country;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.Dto.City
{
    public class CityDto: BaseDto
    {
        public string Name { get; set; }
        public int CountryId { get; set; }
        public CountryDto Country { get; set; }
    }
}
