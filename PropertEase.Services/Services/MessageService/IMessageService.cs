using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.Message;
using PropertEase.Services.Services.BaseService;
using PropertEase.Shared.Hubs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PropertEase.Services.Services.MessageService
{
    public interface IMessageService: IBaseService<MessageDto>
    {
        Task<List<MessageDto>> GetByConversationId(int conversationId);
        Task<MessageDto> AddAsyncSignalR(MessageDto entityDto, IHubContext<MessageHub> hubContext);
        Task MarkConversationAsRead(int conversationId, int recipientId);
        Task<int> GetUnreadCount(int recipientId);
    }
}
