using AspNetCore.Reporting;
using Microsoft.Extensions.Logging;
using MobiFon.Infrastructure.Repositories.PropertyReservationRepository;
using MobiFon.Services.Services.PropertyReservationBackgroundService;
using PropertEase.Core.SearchObjects;
using PropertEase.Reporting.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.ReportingService
{
    public class ReportingService : IReportingService
    {
        public IPropertyReservationRepository propertyReservationRepository;
        private readonly ILogger<ReportingService> logger;

        public ReportingService(IPropertyReservationRepository propertyReservationRepository, ILogger<ReportingService> logger)
        {
            this.propertyReservationRepository = propertyReservationRepository;
            this.logger = logger;

        }
        public async Task<byte[]> CreateEmployeeBusinessReportFile(string pathRdlc, ReportSearchObject reportSearchObject)
        {
            var result = await propertyReservationRepository.GetRenterBusinessReportData(reportSearchObject);
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            LocalReport report = new LocalReport(pathRdlc);
            List<RenterBusinessReportModel> listForReport = new List<RenterBusinessReportModel>();
            foreach (var reservation in result)
            {
                listForReport.Add(new RenterBusinessReportModel
                {
                    ClientName = reservation.Client.Person.FirstName,
                    RenterName = reservation.Renter.Person.LastName,
                    PropertyName = reservation.Property.Name,
                    ReservationNumber = reservation.ReservationNumber,
                    Price = reservation.TotalPrice.ToString(),
                    RentType = reservation.IsDaily ? "Daily" : "Monthly",
                    DateOfPayment = reservation.DateOfOccupancyStart.ToString(),

                }); ;
                logger.LogInformation(reservation.Renter.UserName);


            }
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            parameters.Add("ReportDateCreated", DateTime.Now.ToString());
            report.AddDataSource("dataSetReservations", listForReport);
            var reportResult = report.Execute(RenderType.Pdf, 1, parameters);
            return reportResult.MainStream;
        }
    }
}
