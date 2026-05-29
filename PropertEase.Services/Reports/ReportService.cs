using PropertEase.Infrastructure.UnitOfWork;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace PropertEase.Services.Reports;

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
        var reservations = await _uow.PropertyReservationRepository.GetForReportAsync(ownerId, from, to);

        var doc = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4.Landscape());
                page.Margin(30);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text("PropertEase").Bold().FontSize(18).FontColor(Colors.Blue.Medium);
                    col.Item().Text("Izvještaj o rezervacijama").FontSize(14);
                    col.Item().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
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
                        cols.ConstantColumn(70);
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
                        header.Cell().Element(HeaderCell).Text("Povrat").Bold();
                        header.Cell().Element(HeaderCell).Text("Saldo").Bold();
                    });

                    bool even = false;
                    foreach (var r in reservations)
                    {
                        var bg = even ? Colors.Grey.Lighten5 : Colors.White;
                        even = !even;

                        var refund = r.IsRefunded ? r.TotalPrice : 0;
                        var saldo = r.TotalPrice - refund;

                        IContainer DataCell(IContainer c) => c.Background(bg).Padding(4);

                        table.Cell().Element(DataCell).Text(r.ReservationNumber ?? "-");
                        table.Cell().Element(DataCell).Text(r.Property?.Name ?? "-");
                        table.Cell().Element(DataCell).Text(r.Client?.UserName ?? "-");
                        table.Cell().Element(DataCell).Text(r.DateOfOccupancyStart.ToString("dd.MM.yyyy"));
                        table.Cell().Element(DataCell).Text(r.DateOfOccupancyEnd.ToString("dd.MM.yyyy"));
                        table.Cell().Element(DataCell).Text($"{r.TotalPrice:N2} USD");
                        table.Cell().Element(DataCell)
                            .Text(refund > 0 ? $"-{refund:N2} USD" : "-")
                            .FontColor(refund > 0 ? Colors.Red.Medium : Colors.Black);
                        table.Cell().Element(DataCell)
                            .Text($"{saldo:N2} USD")
                            .FontColor(saldo > 0 ? Colors.Green.Darken1 : Colors.Grey.Medium);
                    }

                    var totalCijena = reservations.Sum(r => r.TotalPrice);
                    var totalPovrat = reservations.Where(r => r.IsRefunded).Sum(r => r.TotalPrice);
                    var totalSaldo = totalCijena - totalPovrat;

                    static IContainer TotalCell(IContainer c) =>
                        c.Background(Colors.Blue.Lighten4).Padding(4);

                    table.Cell().ColumnSpan(5).Element(TotalCell).Text("UKUPNO").Bold();
                    table.Cell().Element(TotalCell).Text($"{totalCijena:N2} USD").Bold();
                    table.Cell().Element(TotalCell)
                        .Text(totalPovrat > 0 ? $"-{totalPovrat:N2} USD" : "-").Bold()
                        .FontColor(totalPovrat > 0 ? Colors.Red.Medium : Colors.Black);
                    table.Cell().Element(TotalCell).Text($"{totalSaldo:N2} USD").Bold()
                        .FontColor(Colors.Blue.Darken2);
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
        var reservations = await _uow.PropertyReservationRepository.GetForReportAsync(ownerId, from, to);

        var grouped = reservations
            .GroupBy(r => r.Property?.Name)
            .Select(g => new
            {
                PropertyName = g.Key,
                ReservationCount = g.Count(),
                Revenue = g.Sum(r => r.TotalPrice),
                Refunds = g.Where(r => r.IsRefunded).Sum(r => r.TotalPrice),
            })
            .OrderByDescending(g => g.Revenue)
            .ToList();

        var totalRevenue = grouped.Sum(g => g.Revenue);
        var totalRefunds = grouped.Sum(g => g.Refunds);
        var totalSaldo = totalRevenue - totalRefunds;

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
                    col.Item().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
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
                            cols.ConstantColumn(90);
                            cols.ConstantColumn(90);
                            cols.ConstantColumn(90);
                        });

                        static IContainer H(IContainer c) =>
                            c.Background(Colors.Blue.Lighten3).Padding(4);

                        table.Header(header =>
                        {
                            header.Cell().Element(H).Text("Nekretnina").Bold();
                            header.Cell().Element(H).Text("Br. rezervacija").Bold();
                            header.Cell().Element(H).Text("Prihod").Bold();
                            header.Cell().Element(H).Text("Povrati").Bold();
                            header.Cell().Element(H).Text("Saldo").Bold();
                        });

                        bool even = false;
                        foreach (var g in grouped)
                        {
                            var bg = even ? Colors.Grey.Lighten5 : Colors.White;
                            even = !even;
                            IContainer D(IContainer c) => c.Background(bg).Padding(4);
                            var saldo = g.Revenue - g.Refunds;

                            table.Cell().Element(D).Text(g.PropertyName ?? "-");
                            table.Cell().Element(D).Text(g.ReservationCount.ToString());
                            table.Cell().Element(D).Text($"{g.Revenue:N2} USD");
                            table.Cell().Element(D)
                                .Text(g.Refunds > 0 ? $"-{g.Refunds:N2} USD" : "-")
                                .FontColor(g.Refunds > 0 ? Colors.Red.Medium : Colors.Black);
                            table.Cell().Element(D)
                                .Text($"{saldo:N2} USD")
                                .FontColor(saldo > 0 ? Colors.Green.Darken1 : Colors.Grey.Medium);
                        }

                        static IContainer Tot(IContainer c) =>
                            c.Background(Colors.Blue.Lighten4).Padding(4);

                        table.Cell().Element(Tot).Text("UKUPNO").Bold();
                        table.Cell().Element(Tot).Text(grouped.Sum(g => g.ReservationCount).ToString()).Bold();
                        table.Cell().Element(Tot).Text($"{totalRevenue:N2} USD").Bold();
                        table.Cell().Element(Tot)
                            .Text(totalRefunds > 0 ? $"-{totalRefunds:N2} USD" : "-").Bold()
                            .FontColor(totalRefunds > 0 ? Colors.Red.Medium : Colors.Black);
                        table.Cell().Element(Tot).Text($"{totalSaldo:N2} USD").Bold()
                            .FontColor(Colors.Blue.Darken2);
                    });

                    col.Item().PaddingTop(10).AlignRight()
                        .Text($"SALDO: {totalSaldo:N2} USD").Bold().FontSize(12)
                        .FontColor(Colors.Blue.Darken2);
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
        var payments = await _uow.PaymentRepository.GetForReportAsync(ownerId, from, to);

        var doc = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4.Landscape());
                page.Margin(30);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text("PropertEase").Bold().FontSize(18).FontColor(Colors.Blue.Medium);
                    col.Item().Text("Izvještaj o plaćanjima").FontSize(14);
                    col.Item().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
                    col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten3);
                });

                page.Content().PaddingTop(10).Table(table =>
                {
                    table.ColumnsDefinition(cols =>
                    {
                        cols.ConstantColumn(85);
                        cols.ConstantColumn(90);
                        cols.RelativeColumn(2);
                        cols.RelativeColumn(3);
                        cols.ConstantColumn(75);
                        cols.ConstantColumn(55);
                        cols.ConstantColumn(70);
                    });

                    static IContainer H(IContainer c) =>
                        c.Background(Colors.Blue.Lighten3).Padding(4);

                    table.Header(header =>
                    {
                        header.Cell().Element(H).Text("Datum").Bold();
                        header.Cell().Element(H).Text("Br. rezervacije").Bold();
                        header.Cell().Element(H).Text("Klijent").Bold();
                        header.Cell().Element(H).Text("PayPal ID").Bold();
                        header.Cell().Element(H).Text("Iznos").Bold();
                        header.Cell().Element(H).Text("Valuta").Bold();
                        header.Cell().Element(H).Text("Status").Bold();
                    });

                    bool even = false;
                    foreach (var p in payments)
                    {
                        var bg = even ? Colors.Grey.Lighten5 : Colors.White;
                        even = !even;
                        IContainer D(IContainer c) => c.Background(bg).Padding(4);

                        var (statusLabel, statusColor) = p.Status switch
                        {
                            PropertEase.Core.Enumerations.PaymentStatus.Completed => ("Završen", Colors.Green.Darken1),
                            PropertEase.Core.Enumerations.PaymentStatus.Refunded  => ("Refundiran", Colors.Red.Medium),
                            PropertEase.Core.Enumerations.PaymentStatus.Pending   => ("Na čekanju", Colors.Orange.Medium),
                            PropertEase.Core.Enumerations.PaymentStatus.Failed    => ("Neuspješan", Colors.Red.Darken3),
                            _                                                      => ("Nepoznat", Colors.Grey.Medium),
                        };

                        table.Cell().Element(D).Text(p.CreatedAt.ToString("dd.MM.yyyy HH:mm"));
                        table.Cell().Element(D).Text(p.Reservation?.ReservationNumber ?? "-");
                        table.Cell().Element(D).Text(p.Client?.UserName ?? "-");
                        table.Cell().Element(D).Text(p.PayPalPaymentId ?? "-");
                        table.Cell().Element(D).Text($"{p.Amount:N2}");
                        table.Cell().Element(D).Text(p.Currency ?? "-");
                        table.Cell().Element(D).Text(statusLabel).FontColor(statusColor);
                    }

                    var totalCompleted = payments
                        .Where(p => p.Status == PropertEase.Core.Enumerations.PaymentStatus.Completed)
                        .Sum(p => p.Amount);
                    var totalRefunded = payments
                        .Where(p => p.Status == PropertEase.Core.Enumerations.PaymentStatus.Refunded)
                        .Sum(p => p.Amount);

                    static IContainer Tot(IContainer c) =>
                        c.Background(Colors.Blue.Lighten4).Padding(4);

                    table.Cell().ColumnSpan(3).Element(Tot).Text("UKUPNO ZAVRŠENO").Bold();
                    table.Cell().Element(Tot).Text("").Bold();
                    table.Cell().Element(Tot).Text($"{totalCompleted:N2}").Bold().FontColor(Colors.Green.Darken1);
                    table.Cell().Element(Tot).Text("").Bold();
                    table.Cell().Element(Tot).Text("").Bold();

                    table.Cell().ColumnSpan(3).Element(Tot).Text("UKUPNO REFUNDIRANO").Bold();
                    table.Cell().Element(Tot).Text("").Bold();
                    table.Cell().Element(Tot)
                        .Text(totalRefunded > 0 ? $"{totalRefunded:N2}" : "-").Bold()
                        .FontColor(totalRefunded > 0 ? Colors.Red.Medium : Colors.Black);
                    table.Cell().Element(Tot).Text("").Bold();
                    table.Cell().Element(Tot).Text("").Bold();
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
}
