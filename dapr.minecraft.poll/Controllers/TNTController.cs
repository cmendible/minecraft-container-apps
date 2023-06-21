using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using dapr.minecraft.poll.Models;
using System.Text.Json;
using System.Text.Json.Serialization;
using Dapr.Actors.Runtime;
using Dapr.Client;

namespace dapr.minecraft.poll.Controllers;

public class TNTController : Controller
{
    
    private readonly ILogger<TNTController> _logger;
    private readonly DaprClient _daprClient;

    public TNTController(ILogger<TNTController> logger, DaprClient daprClient)
    {
        _logger = logger;
        _daprClient = daprClient;
    }

    public IActionResult Index()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    [HttpPost("send-message")]
    public async Task<IActionResult> SendMessageAsync([FromBody] TNTMessage message)
    {
        try
        {
            var eventData = JsonSerializer.Serialize(message);
            await _daprClient.PublishEventAsync("messagebus", "tnt", eventData);
            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending message to Event Hub");
            return StatusCode(500);
        }
    }

    public class TNTMessage
    {
        public int TNTCount { get; set; }
    }

    
}
