using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.Message;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.BaseService;
using MobiFon.Services.Services.MessageService;

namespace MobiFon.Controllers
{

    public class MessageController : BaseController<MessageDto, MessageUpsertDto, MessageUpsertDto, BaseSearchObject>
    {
        private readonly IMessageService messageService;   

        public MessageController(IMessageService messageService, IMapper mapper) : base(messageService, mapper)
        {
            this.messageService = messageService;
        }

        [HttpGet("GetByConversationId/{conversationId}/senderId/{senderId}")]
        public async Task<IActionResult> GetByConversationId(int conversationId, int senderId)
        {
            List<MessageDto> messages = await messageService.GetByConversationId(conversationId, senderId);
            return Ok(messages);
        }

    }
}
