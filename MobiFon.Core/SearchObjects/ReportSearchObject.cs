using PropertEase.Core.Enumerations;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Core.SearchObjects
{
    public class ReportSearchObject
    {
        public ReportType ReportType { get; set; }
        public DateTime DateFrom { get; set; }
        public DateTime DateTo { get; set; }
        public int? RenterId { get; set; } 
    }
}
