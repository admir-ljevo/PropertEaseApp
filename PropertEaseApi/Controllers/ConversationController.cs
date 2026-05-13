using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PropertEase.Core.Dto.Conversation;
using PropertEase.Core.SearchObjects;
using PropertEase.Services.Services.ConversationService;
using PropertEase.Shared.Constants;
using System.Security.Claims;

namespace PropertEase.Controllers
{
    [Authorize]
    public class ConversationController : BaseController<ConversationDto, ConversationUpsertDto, ConversationUpsertDto, BaseSearchObject>
    {

        private IConversationService conversationService;

        public ConversationController(IConversationService conversationService, IMapper mapper) : base(conversationService, mapper)
        {
            this.conversationService = conversationService;
        }

        [NonAction] public override Task<ConversationDto> Get(int id) => throw new NotSupportedException();
        [NonAction] public override Task<ConversationDto> Put(int id, ConversationUpsertDto updateEntity) => throw new NotSupportedException();

        private int GetCallerId() => int.TryParse(User.FindFirstValue("Id"), out var id) ? id : 0;

[HttpGet("GetByPropertyAndRenter")]
        public async Task<IActionResult> GetByPropertyAndRenter([FromQuery] int? propertyId, [FromQuery] int renterId)
        {
            if (GetCallerId() != renterId)
                return Forbid();

            var conversations = await conversationService.GetByPropertyAndRenter(propertyId, renterId);
            return Ok(conversations);
        }

        [HttpGet("GetByClient/clientId/{clientId:int}")]
        public async Task<IActionResult> GetByClient(int clientId)
        {
            if (GetCallerId() != clientId)
                return Forbid();

            var conversations = await conversationService.GetByClient(clientId);
            return Ok(conversations);
        }

        [HttpGet("GetLastByClient/{clientId}")]
        public async Task<IActionResult> GetLastByClient(int clientId)
        {
            if (GetCallerId() != clientId)
                return Forbid();

            var conversations = await conversationService.GetLastByClient(clientId);
            return Ok(conversations);
        }

        [HttpGet("GetAdminConversations/{userId}")]
        public async Task<IActionResult> GetAdminConversations(int userId)
        {
            if (GetCallerId() != userId)
                return Forbid();

            var conversations = await conversationService.GetAdminConversations(userId);
            return Ok(conversations);
        }

        [HttpGet("GetAdmins")]
        public async Task<IActionResult> GetAdmins()
        {
            var admins = await conversationService.GetAdmins();
            return Ok(admins);
        }
    }
}
