

namespace MobiFon.Services.FileManager
{
    public class FileManager : IFileManager
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _webHostEnvironment;

        public FileManager(IConfiguration configuration, IWebHostEnvironment webHostEnvironment)
        {
            _configuration = configuration;
            _webHostEnvironment = webHostEnvironment;
        }

        public string GeneratePathForReport(string path)
        {
            return "https://localhost:44340//uploads/" + path;
        }

        public async Task<string> UploadFile(IFormFile file)
        {
            var filePath = GetFilePath(file);
            await using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(fileStream);
            }
            return NormalizePath(Path.GetRelativePath(_webHostEnvironment.WebRootPath, filePath));
        }

        public async Task<string> UploadThumbnailPhoto(IFormFile file)
        {
            var filePath = GetFilePath(file);
            using var image = await Image.LoadAsync(file.OpenReadStream());
            image.Mutate(x => x.Resize(100, 100));
            await image.SaveAsync(filePath);

            return NormalizePath(Path.GetRelativePath(_webHostEnvironment.WebRootPath, filePath));
        }

        private string GetFilePath(IFormFile file)
        {
            var uploadsDirectoryPath = _configuration.GetSection("Uploads").GetSection("DirectoryPath").Value;
            var fileName = $"{Path.GetFileNameWithoutExtension(file.FileName)}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(_webHostEnvironment.WebRootPath, uploadsDirectoryPath, fileName);

            var directoryPath = Path.GetDirectoryName(filePath);
            if (directoryPath == null)
                return null;

            if (!Directory.Exists(directoryPath))
                Directory.CreateDirectory(directoryPath);

            return filePath;
        }


        private string NormalizePath(string path)
        {
            return "/" + path.Replace(Path.DirectorySeparatorChar, '/');
        }

       

    }
}
