using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Services.Reports;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = $"{AppRoles.Admin},{AppRoles.Renter}")]
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
        var resolvedOwnerId = ResolveOwnerId(ownerId);
        var pdf = await _reportService.GenerateReservationReportAsync(resolvedOwnerId, from, to);
        return File(pdf, "application/pdf", $"rezervacije_{DateTime.UtcNow:yyyyMMdd}.pdf");
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> RevenueReport(
        [FromQuery] int? ownerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var resolvedOwnerId = ResolveOwnerId(ownerId);
        var pdf = await _reportService.GenerateRevenueReportAsync(resolvedOwnerId, from, to);
        return File(pdf, "application/pdf", $"prihodi_{DateTime.UtcNow:yyyyMMdd}.pdf");
    }

    [HttpGet("payments")]
    public async Task<IActionResult> PaymentReport(
        [FromQuery] int? ownerId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var resolvedOwnerId = ResolveOwnerId(ownerId);
        var pdf = await _reportService.GeneratePaymentReportAsync(resolvedOwnerId, from, to);
        return File(pdf, "application/pdf", $"placanja_{DateTime.UtcNow:yyyyMMdd}.pdf");
    }

    private int? ResolveOwnerId(int? queriedOwnerId)
    {
        if (!User.IsInRole(AppRoles.Admin) && User.IsInRole(AppRoles.Renter))
            return int.Parse(User.FindFirstValue("Id")!);
        return queriedOwnerId;
    }
}
