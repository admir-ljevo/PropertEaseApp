using MobiFon.Core.Enumerations;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.ApplicationUser
{
    public class ClientInsertDto
    {
        public string Email { get; set; }
        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Password { get; set; }
        public string PhoneNumber { get; set; }
        public DateTime BirthDate { get; set; }
        public Gender? Gender { get; set; }
        public MarriageStatus? MarriageStatus { get; set; }
        public string Address { get; set; }
        public string PostCode { get; set; }

    }
}
