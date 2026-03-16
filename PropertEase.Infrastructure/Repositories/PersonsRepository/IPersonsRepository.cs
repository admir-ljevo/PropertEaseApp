using PropertEase.Core.Entities;
using PropertEase.Infrastructure.Repositories.BaseRepository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Infrastructure.Repositories.PersonsRepository
{
    public interface IPersonsRepository: IBaseRepository<Person, int>
    {

    }
}
