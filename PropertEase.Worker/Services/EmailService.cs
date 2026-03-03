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

    public async Task SendReservationConfirmationAsync(string to, string clientName, string propertyName,
        string reservationNumber, DateTime checkIn, DateTime checkOut, decimal totalPrice)
    {
        var subject = $"Potvrda rezervacije {reservationNumber}";
        var body = $@"
            <html><body>
            <h2>Poštovani/a {clientName},</h2>
            <p>Vaša rezervacija je uspješno potvrđena.</p>
            <table border='1' cellpadding='8'>
                <tr><td><b>Broj rezervacije</b></td><td>{reservationNumber}</td></tr>
                <tr><td><b>Nekretnina</b></td><td>{propertyName}</td></tr>
                <tr><td><b>Datum prijave</b></td><td>{checkIn:dd.MM.yyyy}</td></tr>
                <tr><td><b>Datum odjave</b></td><td>{checkOut:dd.MM.yyyy}</td></tr>
                <tr><td><b>Ukupna cijena</b></td><td>{totalPrice:C}</td></tr>
            </table>
            <p>Hvala što koristite PropertEase!</p>
            </body></html>";

        await SendGenericEmailAsync(to, subject, body);
    }

    public async Task SendReservationCancellationAsync(string to, string clientName, string propertyName,
        string reservationNumber, string reason)
    {
        var subject = $"Otkazivanje rezervacije {reservationNumber}";
        var body = $@"
            <html><body>
            <h2>Poštovani/a {clientName},</h2>
            <p>Vaša rezervacija je otkazana.</p>
            <table border='1' cellpadding='8'>
                <tr><td><b>Broj rezervacije</b></td><td>{reservationNumber}</td></tr>
                <tr><td><b>Nekretnina</b></td><td>{propertyName}</td></tr>
                <tr><td><b>Razlog</b></td><td>{reason}</td></tr>
            </table>
            </body></html>";

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
