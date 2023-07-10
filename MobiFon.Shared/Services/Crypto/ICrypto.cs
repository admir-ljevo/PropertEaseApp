using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Shared.Services.Crypto
{
    public interface ICrypto
    {
        string GenerateHash(string input, string salt);
        string GenerateSalt();
        bool Verify(string hash, string salt, string input);
        string GeneratePassword(int length = 8);
    }
}
