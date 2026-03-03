using MobiFon.Core.Dto.City;
using MobiFon.Core.Enumerations;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Core.Dto.Person
{
    public class PersonDto: BaseDto
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public DateTime BirthDate { get; set; }
        public Gender? Gender { get; set; }
        public string GenderName { get; set; }
        public string ProfilePhoto { get; set; }
        public string ProfilePhotoThumbnail { get; set; }
        public byte[] ProfilePhotoBytes { get; set; }
        public int? BirthPlaceId { get; set; }
        public CityDto BirthPlace { get; set; }
        public string JMBG { get; set; }
        public string Qualifications { get; set; }
        public int? PlaceOfResidenceId { get; set; }
        public CityDto PlaceOfResidence { get; set; }
        public MarriageStatus? MarriageStatus { get; set; }
        public string MarriageStatusName { get; set; }
        public string Nationality { get; set; }
        public string Citizenship { get; set; }
        public bool WorkExperience { get; set; }
        public string Address { get; set; }
        public string PostCode { get; set; }
        public string Biography { get; set; }
        public Position Position { get; set; }
        public string PositionName { get; set; }
   
        public DateTime? DateOfEmployment { get; set; }
        public float Pay { get; set; }
        public bool MembershipCard { get; set; }
        public int ApplicationUserId { get; set; }
        public override string ToString()
        {
            return FirstName + " " + LastName;
        }
    }
}
