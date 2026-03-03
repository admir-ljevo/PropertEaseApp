using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using MobiFon.Core.Dto.Conversation;
using MobiFon.Core.SearchObjects;
using MobiFon.Services.Services.ConversationService;

namespace MobiFon.Controllers
{
    public class ConversationController : BaseController<ConversationDto, ConversationUpsertDto, ConversationUpsertDto, BaseSearchObject>
    {

        private IConversationService conversationService;

        public ConversationController(IConversationService conversationService, IMapper mapper) : base(conversationService, mapper)
        {
            this.conversationService = conversationService;
        }

        [HttpGet("GetByPropertyId/propertyId/{propertyId}")]
        public async Task<IActionResult> GetByPropertyId(int propertyId)
        {
            var conversations = await conversationService.GetByPropertyId(propertyId);
            return Ok(conversations);
        }


        [HttpGet("GetByPropertyAndRenter")]
        public async Task<IActionResult> GetByPropertyAndRenter([FromQuery] int? propertyId, [FromQuery] int renterId)
        {
            var conversations = await conversationService.GetByPropertyAndRenter(propertyId, renterId);
            return Ok(conversations);
        }


        [HttpGet("GetByClient/clientId/{clientId:int}")]
        public async Task<IActionResult> GetByClient(int clientId)
        {
            var conversations = await conversationService.GetByClient(clientId);
            return Ok(conversations);
        }
        [HttpGet("GetLastByClient/{clientId}")]
        public async Task<IActionResult> GetLastByClient(int clientId)
        {
            var conversations = await conversationService.GetLastByClient(clientId);
            return Ok(conversations);
        }

    }
}
