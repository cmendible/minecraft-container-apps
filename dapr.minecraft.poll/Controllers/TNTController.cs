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
    public async Task<IActionResult> Index()
    {
        var message = new TNTMessage() { TNTCount = 1, Block = "TNT" };
        var eventData = JsonSerializer.Serialize(message);
        await _daprClient.PublishEventAsync("messagebus", "tnt", eventData);
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    public class TNTMessage
    {
        public int TNTCount { get; set; }
        public string Block { get; set; }
    }
}