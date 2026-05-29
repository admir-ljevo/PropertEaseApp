using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PropertEase.Core.Dto.Message;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.BaseService;
using PropertEase.Services.Services.ConversationService;
using PropertEase.Services.Services.MessageService;
using PropertEase.Shared.Constants;
using PropertEase.Shared.Hubs;
using System.Security.Claims;

namespace PropertEase.Controllers
{

    [Authorize]
    public class MessageController : BaseController<MessageDto, MessageUpsertDto, MessageUpsertDto, BaseSearchObject>
    {
        private readonly IMessageService messageService;
        private readonly IHubContext<MessageHub> hubContext;
        private readonly IMapper mapper;
        private readonly IConversationService conversationService;

        public MessageController(IMessageService messageService, IHubContext<MessageHub> hubContext, IMapper mapper, IConversationService conversationService) : base(messageService, mapper)
        {
            this.messageService = messageService;
            this.hubContext = hubContext;
            this.mapper = mapper;
            this.conversationService = conversationService;
        }

        [NonAction] public override Task<List<MessageDto>> Get(int page = 1, int pageSize = 20) => throw new NotSupportedException();
        [NonAction] public override Task<MessageDto> Get(int id) => throw new NotSupportedException();
        [NonAction] public override Task<MessageDto> Post(MessageUpsertDto insertEntity) => throw new NotSupportedException();
        [NonAction] public override Task<MessageDto> Put(int id, MessageUpsertDto updateEntity) => throw new NotSupportedException();
        [NonAction] public override Task<IActionResult> Delete(int id) => throw new NotSupportedException();

        private int GetCallerId() => int.TryParse(User.FindFirstValue("Id"), out var id) ? id : 0;

        private async Task<bool> IsParticipantAsync(int conversationId, int callerId)
        {
            var conversation = await conversationService.GetByIdAsync(conversationId);
            return conversation != null && (conversation.ClientId == callerId || conversation.RenterId == callerId);
        }

        [HttpGet("GetByConversationId/{conversationId}")]
        public async Task<IActionResult> GetByConversationId(
            int conversationId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            if (!await IsParticipantAsync(conversationId, GetCallerId()))
                return Forbid();

            var messages = await messageService.GetByConversationId(conversationId, page, pageSize);
            return Ok(messages);
        }

        [HttpPost("AddMessage")]
        public async Task<IActionResult> AddMessage(MessageUpsertDto messageDto)
        {
            var callerId = GetCallerId();

            if (!await IsParticipantAsync(messageDto.ConversationId, callerId))
                return Forbid();

            messageDto.SenderId = callerId;

            var addedMessage = await messageService.AddAsyncSignalR(mapper.Map<MessageDto>(messageDto), hubContext);
            return Ok(addedMessage);
        }

        [HttpPut("MarkAsRead/{conversationId}")]
        public async Task<IActionResult> MarkAsRead(int conversationId)
        {
            var callerId = GetCallerId();

            if (!await IsParticipantAsync(conversationId, callerId))
                return Forbid();

            await messageService.MarkConversationAsRead(conversationId, callerId, hubContext);
            return Ok();
        }

        [HttpGet("UnreadCount")]
        public async Task<IActionResult> UnreadCount()
        {
            var count = await messageService.GetUnreadCount(GetCallerId());
            return Ok(count);
        }
    }
}
