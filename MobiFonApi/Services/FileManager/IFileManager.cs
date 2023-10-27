﻿namespace MobiFon.Services.FileManager
{
    public interface IFileManager
    {
        Task<string> UploadFile(IFormFile file);
        Task<byte[]> UploadFileAsBase64String(IFormFile file);

        Task<string> UploadThumbnailPhoto(IFormFile file);
        string GeneratePathForReport(string path);
    }
}
