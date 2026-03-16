using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.Message;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.MessageService;
using PropertEase.Shared.Hubs;

namespace PropertEase.Controllers
{

    public class MessageController : BaseController<MessageDto, MessageUpsertDto, MessageUpsertDto, BaseSearchObject>
    {
        private readonly IMessageService messageService;
        private  IHubContext<MessageHub> hubContext;
        private readonly IMapper mapper;

        public MessageController(IMessageService messageService, IHubContext<MessageHub> hubContext, IMapper mapper) : base(messageService, mapper)
        {
            this.messageService = messageService;
            this.hubContext = hubContext;
            this.mapper = mapper;
        }

        [HttpGet("GetByConversationId/{conversationId}")]
        public async Task<IActionResult> GetByConversationId(int conversationId)
        {
            List<MessageDto> messages = await messageService.GetByConversationId(conversationId);
            return Ok(messages);
        }

        [HttpPost("AddMessage")]
        public async Task<IActionResult> AddMessage(MessageUpsertDto messageDto)
        {
           var addedMessage = await messageService.AddAsyncSignalR(mapper.Map<MessageDto>(messageDto), hubContext);
            return Ok(addedMessage);
        }

        [HttpPut("MarkAsRead/{conversationId}")]
        public async Task<IActionResult> MarkAsRead(int conversationId, [FromQuery] int recipientId)
        {
            await messageService.MarkConversationAsRead(conversationId, recipientId);
            return Ok();
        }

        [HttpGet("UnreadCount/{recipientId}")]
        public async Task<IActionResult> UnreadCount(int recipientId)
        {
            var count = await messageService.GetUnreadCount(recipientId);
            return Ok(count);
        }
    }
}
