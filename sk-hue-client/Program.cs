using System.Text.Json.Serialization;
using Dapr;
using Dapr.Client;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using Plugins;
using Options;
using System.Configuration;

// Build the host and configure the services
HostApplicationBuilder builder = Host.CreateApplicationBuilder();
builder.Services.Configure<HueBridgeOptions>(builder.Configuration.GetSection("HueBridgeOptions"));
builder.Services.Configure<BingSearchOptions>(builder.Configuration.GetSection("BingSearchOptions"));
builder.Services.Configure<OpenAIOptions>(builder.Configuration.GetSection("OpenAIOptions"));
var host = builder.Build();

// Create a kernel builder
IKernelBuilder kernelBuilder = Kernel.CreateBuilder();
kernelBuilder.Services.AddSingleton(host.Services.GetRequiredService<IOptions<HueBridgeOptions>>().Value);
kernelBuilder.Services.AddSingleton(host.Services.GetRequiredService<IOptions<BingSearchOptions>>().Value);
kernelBuilder.Services.AddLogging(c => c.AddDebug().SetMinimumLevel(LogLevel.Trace));

// Use a chat completion model from Azure OpenAI
kernelBuilder.AddAzureOpenAIChatCompletion(
deploymentName: host.Services.GetRequiredService<IOptions<OpenAIOptions>>().Value.ChatDeploymentName,
endpoint: host.Services.GetRequiredService<IOptions<OpenAIOptions>>().Value.Endpoint,
apiKey: host.Services.GetRequiredService<IOptions<OpenAIOptions>>().Value.ApiKey
);

// Add the plugins
kernelBuilder.Plugins.AddFromType<Bing>();
kernelBuilder.Plugins.AddFromType<HueLights>();

// Build the kernel and retrieve the AI services
Kernel kernel = kernelBuilder.Build();
IChatCompletionService chatCompletionService = kernel.GetRequiredService<IChatCompletionService>();

var appBuilder = WebApplication.CreateBuilder(args);
var app = appBuilder.Build();
app.UseCloudEvents();

app.MapSubscribeHandler();

if (app.Environment.IsDevelopment()) {app.UseDeveloperExceptionPage();}

app.MapPost("/message", [Topic("eventhubs-pubsub", "bot-commands")] 
async (Message message)  => {
    Console.WriteLine("Incoming Message Received : " + message);
    string promptResponse = string.Empty;
    promptResponse = await sk_hue_client.RunPrompt(kernel, chatCompletionService, message.UserPrompt);
    using var client = new DaprClientBuilder().Build();
    await client.PublishEventAsync("eventhubs-pubsub", "iot_responses", promptResponse);
    Console.WriteLine("Outgoing Message Sent : " + promptResponse);
    return Results.Json(message);
});

app.MapPost("/test", async (Message message) => {
    using var client = new DaprClientBuilder().Build();
    await client.PublishEventAsync("eventhubs-pubsub", "bot-commands", message);
    Console.WriteLine("Test Message Sent : " + message);
    return Results.Ok(message);
});

await app.RunAsync();

public record Message([property: JsonPropertyName("UserPrompt")] string UserPrompt);
