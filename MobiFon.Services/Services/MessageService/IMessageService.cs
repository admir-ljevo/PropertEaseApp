using Microsoft.AspNetCore.SignalR;
using MobiFon.Core.Dto.Message;
using MobiFon.Services.Services.BaseService;
using PropertEase.Shared.Hubs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MobiFon.Services.Services.MessageService
{
    public interface IMessageService: IBaseService<MessageDto>
    {
        Task<List<MessageDto>> GetByConversationId(int conversationId);
        Task<MessageDto> AddAsyncSignalR(MessageDto entityDto, IHubContext<MessageHub> hubContext);
    }
}
