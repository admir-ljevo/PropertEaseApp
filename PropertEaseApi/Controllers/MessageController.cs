using AutoMapper;
using Microsoft.AspNetCore.Authorization;
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

    [Authorize]
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

        [NonAction] public override Task<MessageDto> Get(int id) => throw new NotSupportedException();
        [NonAction] public override Task<MessageDto> Post(MessageUpsertDto insertEntity) => throw new NotSupportedException();

        [HttpGet("GetByConversationId/{conversationId}")]
        public async Task<IActionResult> GetByConversationId(
            int conversationId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            var messages = await messageService.GetByConversationId(conversationId, page, pageSize);
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
            await messageService.MarkConversationAsRead(conversationId, recipientId, hubContext);
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
