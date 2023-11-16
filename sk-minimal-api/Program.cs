global using Microsoft.SemanticKernel;
using System.Text.Json;
using Microsoft.KernelMemory;
using Microsoft.SemanticKernel.Planners;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
                .Build();

// Get model, apiKey, endpoint and openaiKey from appsettings.json
var model = config.GetSection("Values").GetValue<string>("model");
var apiKey = config.GetSection("Values").GetValue<string>("apiKey");
var endpoint = config.GetSection("Values").GetValue<string>("endpoint");
var openaiKey = config.GetSection("Values").GetValue<string>("openaiKey");

// Show model, apiKey, endpoint and openaiKey
Console.WriteLine($"model: {model}");
Console.WriteLine($"apiKey: {apiKey}");
Console.WriteLine($"endpoint: {endpoint}");
Console.WriteLine($"openaiKey: {openaiKey}");

// Check if model, apiKey, endpoint and openaiKey are set
if (string.IsNullOrEmpty(model) || string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(openaiKey))
{
    Console.WriteLine("Please set model, apiKey, endpoint and openaiKey in appsettings.json");
    return;
}


app.MapGet("/", () => "Welcome to Semantic Kernel!");

///plugins/FunPlugin/invoke/Joke?query=Tell%20me%20a%20joke
app.MapPost("plugins/{pluginName}/invoke/{functionName}", async (HttpContext context, string query, string pluginName, string functionName) =>
{
    try
    {
        var kernel = new KernelBuilder()
                            .WithAzureOpenAIChatCompletionService(deploymentName: model, endpoint: endpoint, apiKey: apiKey)
                            .Build();


        var pluginsDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Plugins");

        var funPluginFunctions = kernel.ImportSemanticFunctionsFromDirectory(pluginsDirectory, pluginName);

        var result = await kernel.RunAsync(query, funPluginFunctions[functionName]);

        return Results.Json(new { answer = result.GetValue<string>() });


    }
    catch (Exception ex)
    {
        Console.WriteLine(ex.Message);
        throw;
    }

});

// Que Semantic Kernel elija los plugins que considere para contestar a mi pregunta
app.MapGet("planner", async (HttpContext context, string query) =>
{
    var kernel = new KernelBuilder()
                    .WithAzureOpenAIChatCompletionService(model, endpoint, apiKey)
                    .Build();

    var planner = new SequentialPlanner(kernel);

    var pluginsDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Plugins");
    kernel.ImportSemanticFunctionsFromDirectory(pluginsDirectory, "FunPlugin");

    var plan = await planner.CreatePlanAsync(query);

    Console.WriteLine("Plan:\n");
    Console.WriteLine(JsonSerializer.Serialize(plan, new JsonSerializerOptions { WriteIndented = true }));

    var result = await kernel.RunAsync(plan);

    Console.WriteLine("Result:\n");
    Console.WriteLine(JsonSerializer.Serialize(result, new JsonSerializerOptions { WriteIndented = true }));

    return Results.Json(new { answer = result.GetValue<string>() });


});

// ChatGPT plugin: https://github.com/microsoft/semantic-kernel-starters/tree/main/sk-csharp-chatgpt-plugin
app.MapGet("chatgpt_plugin", async (HttpContext context, string query) =>
{


});


// Kernel Memory

// Load documents
Plugins.MemoryPlugin.MemoryKernel.Init(openaiKey);

app.MapGet("memory", async (HttpContext context, string query) =>
{
    var kernel = new KernelBuilder()
                    .WithAzureOpenAIChatCompletionService(model, endpoint, apiKey)
                    .Build();

    var memoryPlugin = kernel.ImportFunctions(new Plugins.MemoryPlugin.MemoryKernel(), "MemoryPlugin");

    var planner = new SequentialPlanner(kernel);

    var plan = await planner.CreatePlanAsync(query);

    Console.WriteLine("Plan:\n");
    Console.WriteLine(JsonSerializer.Serialize(plan, new JsonSerializerOptions { WriteIndented = true }));

    var result = await kernel.RunAsync(plan);

    return Results.Json(JsonSerializer.Deserialize<Answer>(result.GetValue<string>()));

});


app.Run();