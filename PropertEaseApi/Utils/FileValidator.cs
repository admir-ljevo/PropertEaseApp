namespace PropertEase.Api.Utils;

public static class FileValidator
{
    private static readonly IReadOnlyDictionary<string, byte[]> Signatures = new Dictionary<string, byte[]>
    {
        ["image/jpeg"] = new byte[] { 0xFF, 0xD8, 0xFF },
        ["image/png"]  = new byte[] { 0x89, 0x50, 0x4E, 0x47 },
        ["image/gif"]  = new byte[] { 0x47, 0x49, 0x46 },
        ["image/webp"] = new byte[] { 0x52, 0x49, 0x46, 0x46 },
        ["application/pdf"] = new byte[] { 0x25, 0x50, 0x44, 0x46 },
    };

    public static bool IsValidImage(IFormFile file) =>
        HasValidSignature(file, "image/jpeg", "image/png", "image/gif", "image/webp");

    public static bool HasValidSignature(IFormFile file, params string[] allowedMimeTypes)
    {
        if (file == null || file.Length == 0) return false;

        Span<byte> header = stackalloc byte[8];
        using var stream = file.OpenReadStream();
        var read = stream.Read(header);

        foreach (var mimeType in allowedMimeTypes)
        {
            if (!Signatures.TryGetValue(mimeType, out var sig)) continue;
            if (read >= sig.Length && header[..sig.Length].SequenceEqual(sig))
                return true;
        }
        return false;
    }
}
