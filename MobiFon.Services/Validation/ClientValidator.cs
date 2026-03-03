using FluentValidation;
using MobiFon.Core.Dto.ApplicationUser;

namespace MobiFon.Services.Validation;

public class ClientUpsertValidator : AbstractValidator<ClientInsertDto>
{
    private readonly bool _isCreate;

    public ClientUpsertValidator(bool isCreate = true)
    {
        _isCreate = isCreate;

        RuleFor(x => x.UserName)
            .NotEmpty().WithMessage("Korisničko ime je obavezno.")
            .MinimumLength(3).WithMessage("Korisničko ime mora imati najmanje 3 znaka.")
            .MaximumLength(50).WithMessage("Korisničko ime ne smije biti duže od 50 znakova.")
            .Matches("^[a-zA-Z0-9_.-]+$").WithMessage("Korisničko ime smije sadržavati samo slova, brojeve i znakove _.-");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email adresa je obavezna.")
            .EmailAddress().WithMessage("Unesite ispravnu email adresu.");

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[0-9\s\-]{7,15}$").When(x => !string.IsNullOrEmpty(x.PhoneNumber))
            .WithMessage("Unesite ispravan format broja telefona.");

        // Password required only on create
        When(_ => _isCreate, () =>
        {
            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 znakova.")
                .Matches("[A-Z]").WithMessage("Lozinka mora sadržavati najmanje jedno veliko slovo.")
                .Matches("[0-9]").WithMessage("Lozinka mora sadržavati najmanje jedan broj.");
        });

        // Password optional on edit – validate only if provided
        When(_ => !_isCreate, () =>
        {
            RuleFor(x => x.Password)
                .MinimumLength(6).When(x => !string.IsNullOrEmpty(x.Password))
                .WithMessage("Nova lozinka mora imati najmanje 6 znakova.")
                .Matches("[A-Z]").When(x => !string.IsNullOrEmpty(x.Password))
                .WithMessage("Nova lozinka mora sadržavati najmanje jedno veliko slovo.");
        });
    }
}
