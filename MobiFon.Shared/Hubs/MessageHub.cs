using Microsoft.AspNet.SignalR.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace PropertEase.Shared.Hubs;
//[HubName("MessageHub")] 

public class MessageHub : Hub
{
    protected IHubContext<MessageHub> _context;

    public MessageHub(IHubContext<MessageHub> context)
    {
        _context = context;
    }

}
