using MobiFon.Infrastructure.UnitOfWork;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MobiFon.Services.Reports;

public class ReportService : IReportService
{
    private readonly UnitOfWork _uow;

    public ReportService(IUnitOfWork unitOfWork)
    {
        _uow = (UnitOfWork)unitOfWork;
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<byte[]> GenerateReservationReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null)
    {
        var reservations = await _uow.PropertyReservationRepository.GetAllAsync();

        if (ownerId.HasValue)
            reservations = reservations.Where(r => r.Property?.ApplicationUserId == ownerId).ToList();
        if (from.HasValue)
            reservations = reservations.Where(r => r.DateOfOccupancyStart >= from.Value).ToList();
        if (to.HasValue)
            reservations = reservations.Where(r => r.DateOfOccupancyEnd <= to.Value).ToList();

        var doc = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(30);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text("PropertEase").Bold().FontSize(18).FontColor(Colors.Blue.Medium);
                    col.Item().Text("Izvještaj o rezervacijama").FontSize(14);
                    col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
                    col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten3);
                });

                page.Content().PaddingTop(10).Table(table =>
                {
                    table.ColumnsDefinition(cols =>
                    {
                        cols.ConstantColumn(90);
                        cols.RelativeColumn(2);
                        cols.RelativeColumn(2);
                        cols.ConstantColumn(75);
                        cols.ConstantColumn(75);
                        cols.ConstantColumn(70);
                    });

                    static IContainer HeaderCell(IContainer c) =>
                        c.Background(Colors.Blue.Lighten3).Padding(4);

                    table.Header(header =>
                    {
                        header.Cell().Element(HeaderCell).Text("Br. rezervacije").Bold();
                        header.Cell().Element(HeaderCell).Text("Nekretnina").Bold();
                        header.Cell().Element(HeaderCell).Text("Klijent").Bold();
                        header.Cell().Element(HeaderCell).Text("Datum od").Bold();
                        header.Cell().Element(HeaderCell).Text("Datum do").Bold();
                        header.Cell().Element(HeaderCell).Text("Cijena").Bold();
                    });

                    bool even = false;
                    foreach (var r in reservations)
                    {
                        var bg = even ? Colors.Grey.Lighten5 : Colors.White;
                        even = !even;

                        IContainer DataCell(IContainer c) => c.Background(bg).Padding(4);

                        table.Cell().Element(DataCell).Text(r.ReservationNumber ?? "-");
                        table.Cell().Element(DataCell).Text(r.Property?.Name ?? "-");
                        table.Cell().Element(DataCell).Text(r.Client?.UserName ?? "-");
                        table.Cell().Element(DataCell).Text(r.DateOfOccupancyStart.ToString("dd.MM.yyyy"));
                        table.Cell().Element(DataCell).Text(r.DateOfOccupancyEnd.ToString("dd.MM.yyyy"));
                        table.Cell().Element(DataCell).Text($"{r.TotalPrice:N2} KM");
                    }
                });

                page.Footer().AlignRight().Text(text =>
                {
                    text.Span("Stranica ").FontSize(9);
                    text.CurrentPageNumber().FontSize(9);
                    text.Span(" od ").FontSize(9);
                    text.TotalPages().FontSize(9);
                });
            });
        });

        return doc.GeneratePdf();
    }

    public async Task<byte[]> GenerateRevenueReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null)
    {
        var reservations = await _uow.PropertyReservationRepository.GetAllAsync();

        if (ownerId.HasValue)
            reservations = reservations.Where(r => r.Property?.ApplicationUserId == ownerId).ToList();
        if (from.HasValue)
            reservations = reservations.Where(r => r.DateOfOccupancyStart >= from.Value).ToList();
        if (to.HasValue)
            reservations = reservations.Where(r => r.DateOfOccupancyEnd <= to.Value).ToList();

        var grouped = reservations
            .GroupBy(r => r.Property?.Name)
            .Select(g => new { PropertyName = g.Key, ReservationCount = g.Count(), Revenue = g.Sum(r => r.TotalPrice) })
            .OrderByDescending(g => g.Revenue)
            .ToList();

        var totalRevenue = grouped.Sum(g => g.Revenue);

        var doc = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(30);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text("PropertEase").Bold().FontSize(18).FontColor(Colors.Blue.Medium);
                    col.Item().Text("Izvještaj o prihodima").FontSize(14);
                    col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
                    col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten3);
                });

                page.Content().PaddingTop(10).Column(col =>
                {
                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(cols =>
                        {
                            cols.RelativeColumn(3);
                            cols.ConstantColumn(80);
                            cols.ConstantColumn(100);
                        });

                        static IContainer H(IContainer c) =>
                            c.Background(Colors.Blue.Lighten3).Padding(4);

                        table.Header(header =>
                        {
                            header.Cell().Element(H).Text("Nekretnina").Bold();
                            header.Cell().Element(H).Text("Br. rezervacija").Bold();
                            header.Cell().Element(H).Text("Prihod").Bold();
                        });

                        bool even = false;
                        foreach (var g in grouped)
                        {
                            var bg = even ? Colors.Grey.Lighten5 : Colors.White;
                            even = !even;
                            IContainer D(IContainer c) => c.Background(bg).Padding(4);

                            table.Cell().Element(D).Text(g.PropertyName ?? "-");
                            table.Cell().Element(D).Text(g.ReservationCount.ToString());
                            table.Cell().Element(D).Text($"{g.Revenue:N2} KM");
                        }
                    });

                    col.Item().PaddingTop(10).AlignRight()
                        .Text($"UKUPNI PRIHOD: {totalRevenue:N2} KM").Bold().FontSize(12);
                });

                page.Footer().AlignRight().Text(text =>
                {
                    text.Span("Stranica ").FontSize(9);
                    text.CurrentPageNumber().FontSize(9);
                    text.Span(" od ").FontSize(9);
                    text.TotalPages().FontSize(9);
                });
            });
        });

        return doc.GeneratePdf();
    }

    public async Task<byte[]> GeneratePaymentReportAsync(int? ownerId = null, DateTime? from = null, DateTime? to = null)
    {
        return await GenerateReservationReportAsync(ownerId, from, to);
    }
}
