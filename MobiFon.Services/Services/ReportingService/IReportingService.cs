using PropertEase.Core.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.ReportingService
{
    public interface IReportingService
    {
        Task<byte[]> CreateEmployeeBusinessReportFile(string pathRdlc, ReportSearchObject reportSearchObject);

    }
}
