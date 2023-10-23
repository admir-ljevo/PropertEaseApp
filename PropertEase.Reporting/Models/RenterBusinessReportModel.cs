using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Reporting.Models
{
    public class RenterBusinessReportModel

    { 
        public string RenterName { get; set; }
        public string ClientName { get; set; }
        public string ReservationNumber { get; set; }
        public string Price { get; set; }
        public string PropertyName { get; set; }
        public string DateOfPayment { get; set; }
        public string RentType { get; set; }
    }
}
