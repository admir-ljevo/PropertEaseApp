/// Centralized validators for all forms.
/// Each validator returns a descriptive error message with format hints,
/// or null if the value is valid.
class AppValidators {
  AppValidators._();

  static String? name(String? v, {String label = 'Polje'}) {
    if (v == null || v.trim().isEmpty) return '$label je obavezno';
    if (v.trim().length < 2) return '$label mora imati najmanje 2 znaka';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Korisničko ime je obavezno';
    if (v.trim().length < 3) {
      return 'Korisničko ime mora imati najmanje 3 znaka';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v.trim())) {
      return 'Korisničko ime smije sadržavati samo slova, brojeve, _ i .';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-mail adresa je obavezna';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Unesite ispravnu e-mail adresu (npr. korisnik@domena.com)';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Broj telefona je obavezan';
    if (!RegExp(r'^\+?[\d\s\-\(\)]{6,20}$').hasMatch(v.trim())) {
      return 'Unesite ispravan broj telefona (npr. +387 61 234 567)';
    }
    return null;
  }

  static String? jmbg(String? v, {bool required = true}) {
    if (v == null || v.trim().isEmpty) {
      return required ? 'JMBG je obavezan' : null;
    }
    if (!RegExp(r'^\d{13}$').hasMatch(v.trim())) {
      return 'JMBG mora sadržavati tačno 13 cifara';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Lozinka je obavezna';
    if (v.length < 6) return 'Lozinka mora imati najmanje 6 znakova';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Lozinka mora sadržavati barem jedno veliko slovo (A–Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Lozinka mora sadržavati barem jedno malo slovo (a–z)';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Lozinka mora sadržavati barem jednu cifru (0–9)';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(
          String Function() getPassword) =>
      (String? v) {
        if (v == null || v.isEmpty) return 'Potvrda lozinke je obavezna';
        if (v != getPassword()) return 'Lozinke se ne podudaraju';
        return null;
      };

  static String? required(String? v, {String label = 'Ovo polje'}) {
    if (v == null || v.trim().isEmpty) return '$label je obavezno';
    return null;
  }

  static String? positiveDecimal(String? v, {String label = 'Cijena'}) {
    if (v == null || v.trim().isEmpty) return '$label je obavezna';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return '$label mora biti broj (npr. 150.00)';
    if (n <= 0) return '$label mora biti veća od nule';
    return null;
  }

  static String? positiveInt(String? v, {String label = 'Vrijednost'}) {
    if (v == null || v.trim().isEmpty) return '$label je obavezna';
    final n = int.tryParse(v.trim());
    if (n == null) return '$label mora biti cijeli broj';
    if (n <= 0) return '$label mora biti veća od nule';
    return null;
  }
}
