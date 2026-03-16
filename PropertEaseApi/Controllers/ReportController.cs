using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.Reports;

namespace PropertEase.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "1,2")]
public class ReportController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("reservations")]
    public async Task<IActionResult> ReservationReport(
        [FromQuery] int? ownerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var pdf = await _reportService.GenerateReservationReportAsync(ownerId, from, to);
        return File(pdf, "application/pdf", $"rezervacije_{DateTime.Now:yyyyMMdd}.pdf");
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> RevenueReport(
        [FromQuery] int? ownerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var pdf = await _reportService.GenerateRevenueReportAsync(ownerId, from, to);
        return File(pdf, "application/pdf", $"prihodi_{DateTime.Now:yyyyMMdd}.pdf");
    }

    [HttpGet("payments")]
    public async Task<IActionResult> PaymentReport(
        [FromQuery] int? ownerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var pdf = await _reportService.GeneratePaymentReportAsync(ownerId, from, to);
        return File(pdf, "application/pdf", $"placanja_{DateTime.Now:yyyyMMdd}.pdf");
    }
}
