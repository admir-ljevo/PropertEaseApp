using MobiFon.Core.Entities.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using MobiFon.Core.Enumerations;

namespace MobiFon.Core.Entities
{
    public class Person: BaseEntity
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public DateTime BirthDate { get; set; }
        public Gender? Gender { get; set; }
        public string? ProfilePhoto { get; set; }
        public string? ProfilePhotoThumbnail { get; set; }
        public int? BirthPlaceId { get; set; }
        public City? BirthPlace { get; set; }
        public string? JMBG { get; set; }
        public string? Qualifications { get; set; }
        public int? PlaceOfResidenceId { get; set; }
        public City? PlaceOfResidence { get; set; }
        public MarriageStatus? MarriageStatus { get; set; }
        public string? Nationality { get; set; }
        public string? Citizenship { get; set; }
        public bool WorkExperience { get; set; }
        public string Address { get; set; }
        public string PostCode { get; set; }
        public string? Biography { get; set; }
        public Position? Position { get; set; }
        public DateTime? DateOfEmployment { get; set; }
        public float? Pay { get; set; }
        public bool MembershipCard { get; set; }
        public int ApplicationUserId { get; set; }
    }
}
