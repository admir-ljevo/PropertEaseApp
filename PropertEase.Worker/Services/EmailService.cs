using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;

namespace PropertEase.Worker.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    private string BuildEmailTemplate(string title, string content, string headerColor)
    {
        return $@"
<!DOCTYPE html>
<html>
<body style='margin:0;padding:0;background:#f4f6f8;font-family:Arial,Helvetica,sans-serif;'>

<table width='100%' cellpadding='0' cellspacing='0' style='padding:40px 0;background:#f4f6f8;'>
<tr>
<td align='center'>

<table width='600' cellpadding='0' cellspacing='0'
style='background:#ffffff;border-radius:10px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.05);'>

<tr>
<td style='background:{headerColor};color:white;padding:24px;font-size:20px;font-weight:bold;text-align:center'>
{title}
</td>
</tr>

<tr>
<td style='padding:32px;color:#333;font-size:15px;line-height:1.6'>
{content}
</td>
</tr>

<tr>
<td style='background:#f4f6f8;text-align:center;padding:20px;font-size:12px;color:#777'>
© {DateTime.Now.Year} PropertEase
</td>
</tr>

</table>

</td>
</tr>
</table>

</body>
</html>";
    }

    public async Task SendReservationConfirmationAsync(
        string to,
        string clientName,
        string propertyName,
        string reservationNumber,
        DateTime checkIn,
        DateTime checkOut,
        decimal totalPrice)
    {
        var subject = $"Potvrda rezervacije {reservationNumber}";

        var content = $@"
<h2 style='margin-top:0'>Poštovani/a {clientName},</h2>

<p>Vaša rezervacija je uspješno potvrđena.</p>

<table width='100%' cellpadding='10' cellspacing='0'
style='border-collapse:collapse;margin-top:20px'>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Broj rezervacije</td>
<td>{reservationNumber}</td>
</tr>

<tr>
<td style='font-weight:bold'>Nekretnina</td>
<td>{propertyName}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Datum prijave</td>
<td>{checkIn:dd.MM.yyyy}</td>
</tr>

<tr>
<td style='font-weight:bold'>Datum odjave</td>
<td>{checkOut:dd.MM.yyyy}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Ukupna cijena</td>
<td style='font-weight:bold;color:#2f80ed'>{totalPrice:C}</td>
</tr>

</table>

<p style='margin-top:30px'>
Hvala što koristite <b>PropertEase</b>.
</p>";

        var body = BuildEmailTemplate(
            "Rezervacija potvrđena",
            content,
            "#2f80ed"
        );

        await SendGenericEmailAsync(to, subject, body);
    }

    public async Task SendReservationCancellationAsync(
        string to,
        string clientName,
        string propertyName,
        string reservationNumber,
        string reason)
    {
        var subject = $"Otkazivanje rezervacije {reservationNumber}";

        var content = $@"
<h2 style='margin-top:0'>Poštovani/a {clientName},</h2>

<p>Vaša rezervacija je otkazana.</p>

<table width='100%' cellpadding='10' cellspacing='0'
style='border-collapse:collapse;margin-top:20px'>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Broj rezervacije</td>
<td>{reservationNumber}</td>
</tr>

<tr>
<td style='font-weight:bold'>Nekretnina</td>
<td>{propertyName}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Razlog</td>
<td>{reason}</td>
</tr>

</table>";

        var body = BuildEmailTemplate(
            "Rezervacija otkazana",
            content,
            "#eb5757"
        );

        await SendGenericEmailAsync(to, subject, body);
    }

    public async Task SendRenterReservationCancelledAsync(
        string to,
        string renterName,
        string clientName,
        string propertyName,
        string reservationNumber,
        DateTime checkIn,
        DateTime checkOut,
        decimal totalPrice,
        string reason)
    {
        var subject = $"Rezervacija {reservationNumber} je otkazana";

        var content = $@"
<h2 style='margin-top:0'>Poštovani/a {renterName},</h2>

<p>Rezervacija za vašu nekretninu je otkazana.</p>

<table width='100%' cellpadding='10' cellspacing='0'
style='border-collapse:collapse;margin-top:20px'>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Broj rezervacije</td>
<td>{reservationNumber}</td>
</tr>

<tr>
<td style='font-weight:bold'>Nekretnina</td>
<td>{propertyName}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Klijent</td>
<td>{clientName}</td>
</tr>

<tr>
<td style='font-weight:bold'>Datum prijave</td>
<td>{checkIn:dd.MM.yyyy}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Datum odjave</td>
<td>{checkOut:dd.MM.yyyy}</td>
</tr>

<tr>
<td style='font-weight:bold'>Ukupna cijena</td>
<td style='font-weight:bold;color:#eb5757'>{totalPrice:C}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Razlog</td>
<td>{reason}</td>
</tr>

</table>

<p style='margin-top:30px'>
Ako imate pitanja, kontaktirajte podršku putem <b>PropertEase</b> platforme.
</p>";

        var body = BuildEmailTemplate(
            "Rezervacija otkazana",
            content,
            "#eb5757"
        );

        await SendGenericEmailAsync(to, subject, body);
    }

    public async Task SendRenterNewReservationAsync(
        string to,
        string renterName,
        string clientName,
        string propertyName,
        string reservationNumber,
        DateTime checkIn,
        DateTime checkOut,
        decimal totalPrice)
    {
        var subject = $"Nova rezervacija {reservationNumber} za vašu nekretninu";

        var content = $@"
<h2 style='margin-top:0'>Poštovani/a {renterName},</h2>

<p>Primili ste novu rezervaciju za vašu nekretninu.</p>

<table width='100%' cellpadding='10' cellspacing='0'
style='border-collapse:collapse;margin-top:20px'>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Broj rezervacije</td>
<td>{reservationNumber}</td>
</tr>

<tr>
<td style='font-weight:bold'>Nekretnina</td>
<td>{propertyName}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Klijent</td>
<td>{clientName}</td>
</tr>

<tr>
<td style='font-weight:bold'>Datum prijave</td>
<td>{checkIn:dd.MM.yyyy}</td>
</tr>

<tr style='background:#f7f9fc'>
<td style='font-weight:bold'>Datum odjave</td>
<td>{checkOut:dd.MM.yyyy}</td>
</tr>

<tr>
<td style='font-weight:bold'>Ukupna cijena</td>
<td style='font-weight:bold;color:#27ae60'>{totalPrice:C}</td>
</tr>

</table>

<p style='margin-top:30px'>
Provjerite detalje rezervacije u vašem PropertEase dashboardu.
</p>";

        var body = BuildEmailTemplate(
            "Nova rezervacija",
            content,
            "#27ae60"
        );

        await SendGenericEmailAsync(to, subject, body);
    }



    public async Task SendGenericEmailAsync(string to, string subject, string htmlBody)
    {
        var smtpHost = _config["Smtp:Host"] ?? throw new InvalidOperationException("SMTP host not configured");
        var smtpPort = int.Parse(_config["Smtp:Port"] ?? "587");
        var smtpUser = _config["Smtp:Username"] ?? throw new InvalidOperationException("SMTP username not configured");
        var smtpPass = _config["Smtp:Password"] ?? throw new InvalidOperationException("SMTP password not configured");
        var fromName = _config["Smtp:FromName"] ?? "PropertEase";

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, smtpUser));
        message.To.Add(MailboxAddress.Parse(to));
        message.Subject = subject;
        message.Body = new TextPart("html") { Text = htmlBody };

        using var smtp = new SmtpClient();
        try
        {
            await smtp.ConnectAsync(smtpHost, smtpPort, SecureSocketOptions.StartTls);
            await smtp.AuthenticateAsync(smtpUser, smtpPass);
            await smtp.SendAsync(message);
            _logger.LogInformation("Email sent to {To} with subject {Subject}", to, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {To}", to);
            throw;
        }
        finally
        {
            await smtp.DisconnectAsync(true);
        }
    }
}
