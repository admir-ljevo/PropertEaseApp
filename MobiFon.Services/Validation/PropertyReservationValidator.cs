using FluentValidation;
using MobiFon.Core.Dto.PropertyReservation;

namespace MobiFon.Services.Validation;

public class PropertyReservationValidator : AbstractValidator<PropertyReservationUpsertDto>
{
    public PropertyReservationValidator()
    {
        RuleFor(x => x.PropertyId)
            .GreaterThan(0).WithMessage("Nekretnina mora biti odabrana.");

        RuleFor(x => x.ClientId)
            .GreaterThan(0).WithMessage("Klijent mora biti odabran.");

        RuleFor(x => x.NumberOfGuests)
            .InclusiveBetween(1, 20).WithMessage("Broj gostiju mora biti između 1 i 20.");

        RuleFor(x => x.DateOfOccupancyStart)
            .NotEmpty().WithMessage("Datum početka rezervacije je obavezan.")
            .GreaterThanOrEqualTo(DateTime.Today).WithMessage("Datum početka ne može biti u prošlosti.");

        RuleFor(x => x.DateOfOccupancyEnd)
            .NotEmpty().WithMessage("Datum završetka rezervacije je obavezan.")
            .GreaterThan(x => x.DateOfOccupancyStart)
            .WithMessage("Datum završetka mora biti nakon datuma početka.");

        RuleFor(x => x.Description)
            .MaximumLength(500).WithMessage("Opis ne smije biti duži od 500 znakova.");
    }
}
