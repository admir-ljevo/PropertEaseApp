using FluentValidation;
using MobiFon.Core.Dto.Property;

namespace MobiFon.Services.Validation;

public class PropertyValidator : AbstractValidator<PropertyUpsertDto>
{
    public PropertyValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv nekretnine je obavezan.")
            .MinimumLength(3).WithMessage("Naziv mora imati najmanje 3 znaka.")
            .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");

        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("Adresa je obavezna.")
            .MaximumLength(200).WithMessage("Adresa ne smije biti duža od 200 znakova.");

        RuleFor(x => x.Description)
            .MaximumLength(2000).WithMessage("Opis ne smije biti duži od 2000 znakova.");

        RuleFor(x => x.CityId)
            .GreaterThan(0).WithMessage("Grad mora biti odabran.");

        RuleFor(x => x.PropertyTypeId)
            .GreaterThan(0).WithMessage("Tip nekretnine mora biti odabran.");

        RuleFor(x => x.MonthlyPrice)
            .GreaterThan(0).When(x => x.IsMonthly)
            .WithMessage("Mjesečna cijena mora biti veća od 0 ako je odabran mjesečni najam.");

        RuleFor(x => x.DailyPrice)
            .GreaterThan(0).When(x => x.IsDaily)
            .WithMessage("Dnevna cijena mora biti veća od 0 ako je odabran dnevni najam.");

        RuleFor(x => x)
            .Must(x => x.IsMonthly || x.IsDaily)
            .WithMessage("Mora biti odabran najmanje jedan tip najma (dnevni ili mjesečni).")
            .WithName("RentType");

        RuleFor(x => x.Capacity)
            .InclusiveBetween(1, 50).WithMessage("Kapacitet mora biti između 1 i 50.");

        RuleFor(x => x.Latitude)
            .InclusiveBetween(-90, 90).When(x => x.Latitude != 0)
            .WithMessage("Geografska širina mora biti između -90 i 90.");

        RuleFor(x => x.Longitude)
            .InclusiveBetween(-180, 180).When(x => x.Longitude != 0)
            .WithMessage("Geografska dužina mora biti između -180 i 180.");
    }
}
