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


        [HttpGet("GetByPropertyAndRenter/propertyId/{propertyId:int}/renterId/{renterId:int}")]
        public async Task<IActionResult> GetByPropertyAndRenter(int propertyId, int renterId)
        {
            var conversations = await conversationService.GetByPropertyAndRenter(propertyId, renterId);
            return Ok(conversations);
        }

    }
}
