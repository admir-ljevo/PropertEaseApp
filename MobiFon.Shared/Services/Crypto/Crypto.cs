using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using System.Security.Cryptography;
using System.Text;

namespace MobiFon.Shared.Services.Crypto
{
    public class Crypto : ICrypto
    {
        public string GenerateHash(string input, string salt)
        {
            var valueBytes = KeyDerivation.Pbkdf2(
                password: input,
                salt: Encoding.UTF8.GetBytes(salt),
                prf: KeyDerivationPrf.HMACSHA512,
                iterationCount: 10000,
                numBytesRequested: 256 / 8
            );

            return Convert.ToBase64String(valueBytes);
        }

        public string GenerateSalt()
        {
            byte[] randomBytes = new byte[128 / 8];

            using (var generator = RandomNumberGenerator.Create())
            {
                generator.GetBytes(randomBytes);
                return Convert.ToBase64String(randomBytes);
            }
        }
        public bool Verify(string hash, string salt, string input)
        {
            return GenerateHash(input, salt) == hash;
        }

        public string GeneratePassword(int length = 8)
        {
            var lowerChars = "abcdefghijklmnopqrstuvwxyz";
            var upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            var digits = "1234567890";

            string password = "";

            var rnd = new Random();

            for (int i = 0; i < length; i++)
                password += lowerChars[rnd.Next(lowerChars.Length)];

            for (int i = 0; i < 2; i++)
                password += upperChars[rnd.Next(upperChars.Length)];

            for (int i = 0; i < 1; i++)
                password += digits[rnd.Next(digits.Length)];

            return password;
        }
    }
}
