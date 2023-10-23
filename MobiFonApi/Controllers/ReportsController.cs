using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Services.FileManager;
using MobiFon.Services.Services.PropertyReservationService;
using PropertEase.Core.Enumerations;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.ReportingService;
using PropertEase.Shared.Constants;

namespace PropertEase.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReportsController : ControllerBase
    {
        private IReportingService reportService;
        private IPropertyReservationService propertyReservationService;
        private IFileManager fileManager;

        public ReportsController(IReportingService reportService, IPropertyReservationService propertyReservationService, IFileManager fileManager )
        {
            this.reportService = reportService;
            this.propertyReservationService = propertyReservationService;
            this.fileManager = fileManager; 
        }

        [HttpGet]
        [Route("renter")]
        public async Task<IActionResult> ExportRenterReservations([FromQuery] ReportSearchObject reportSearchObject)
        {
            if(reportSearchObject.ReportType == ReportType.Preview)
            {
                return Ok(await propertyReservationService.GetRenterBusinessReportData(reportSearchObject));
            }
            if(reportSearchObject.ReportType == ReportType.PDF)
            {
                var byteRes = new byte[] { };
                string path = fileManager.GeneratePathForReport(ReportPath.RentersReport);
                byteRes = await reportService.CreateEmployeeBusinessReportFile(path, reportSearchObject);
                return File(byteRes, System.Net.Mime.MediaTypeNames.Application.Octet,
                    $"{ReportNames.RenterReport}.pdf");
            }
            return Ok();

        }

    }
}
