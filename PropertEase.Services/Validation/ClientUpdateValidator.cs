using FluentValidation;
using PropertEase.Core.Dto.ApplicationUser;

namespace PropertEase.Services.Validation;

public class ClientUpdateValidator : AbstractValidator<ClientUpdateDto>
{
    public ClientUpdateValidator()
    {
        RuleFor(x => x.UserName)
            .NotEmpty().WithMessage("Korisničko ime je obavezno.")
            .MinimumLength(3).WithMessage("Korisničko ime mora imati najmanje 3 znaka.")
            .MaximumLength(50).WithMessage("Korisničko ime ne smije biti duže od 50 znakova.")
            .Matches("^[a-zA-Z0-9_.-]+$").WithMessage("Korisničko ime smije sadržavati samo slova, brojeve i znakove _.-");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email adresa je obavezna.")
            .EmailAddress().WithMessage("Unesite ispravnu email adresu.");

        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("Ime je obavezno.")
            .MinimumLength(2).WithMessage("Ime mora imati najmanje 2 znaka.");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Prezime je obavezno.")
            .MinimumLength(2).WithMessage("Prezime mora imati najmanje 2 znaka.");

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[0-9\s\-]{7,15}$").When(x => !string.IsNullOrEmpty(x.PhoneNumber))
            .WithMessage("Unesite ispravan format broja telefona.");

        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("Adresa je obavezna.");

        RuleFor(x => x.PostCode)
            .NotEmpty().WithMessage("Poštanski broj je obavezan.");

        RuleFor(x => x.Jmbg)
            .NotEmpty().WithMessage("JMBG je obavezan.")
            .Matches(@"^\d{13}$").WithMessage("JMBG mora imati tačno 13 cifara.");
    }
}
