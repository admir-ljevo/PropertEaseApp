using Microsoft.AspNetCore.Http;
using MobiFon.Core.Dto.Property;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Photo
{
    public class PhotoUpsertDto: BaseDto
    {
        public string Url { get; set; }
        public int? PropertyId { get; set; }
        public IFormFile? File { get; set; }
    }
}
