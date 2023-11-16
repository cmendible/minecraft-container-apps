global using Microsoft.SemanticKernel;
using System.Text.Json;
using Microsoft.KernelMemory;
using Microsoft.SemanticKernel.Planners;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddEnvironmentVariables()           
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
                .Build();

// Get model, apiKey, endpoint and openaiKey from environment variables or appsettings.json
var model = Environment.GetEnvironmentVariable("model") ?? config.GetSection("Values").GetValue<string>("model");
var apiKey = Environment.GetEnvironmentVariable("apiKey") ?? config.GetSection("Values").GetValue<string>("apiKey");
var endpoint = Environment.GetEnvironmentVariable("endpoint") ?? config.GetSection("Values").GetValue<string>("endpoint");
var openaiKey = Environment.GetEnvironmentVariable("openaiKey") ?? config.GetSection("Values").GetValue<string>("openaiKey");
var qdrant = Environment.GetEnvironmentVariable("qdrant") ?? config.GetSection("Values").GetValue<string>("qdrant");


// Check if model, apiKey, endpoint and openaiKey are set
if (string.IsNullOrEmpty(model) || string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(openaiKey))
{
    Console.WriteLine("Please set model, apiKey, endpoint and openaiKey in appsettings.json");
    return;
}


app.MapGet("/", () => "Welcome to Semantic Kernel!");


/*****************************************************************************************
*********************************** Semantic Functions ***********************************
*****************************************************************************************/
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


/*****************************************************************************************
*********************************** Planner *********************************************
*****************************************************************************************/
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


/*****************************************************************************************
*********************************** Kernel Memory ****************************************
*****************************************************************************************/

// First, load some documents... about Minecraft! 😙
Plugins.MemoryPlugin.MemoryKernel.Init(openaiKey);

app.MapGet("memory", async (HttpContext context, string query) =>
{
    var kernel = new KernelBuilder()
                    .WithAzureOpenAIChatCompletionService(model, endpoint, apiKey)
                    .Build();

    var pluginsDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Plugins");
    kernel.ImportSemanticFunctionsFromDirectory(pluginsDirectory, "FunPlugin");
    var memoryPlugin = kernel.ImportFunctions(new Plugins.MemoryPlugin.MemoryKernel(), "MemoryPlugin");

    var planner = new SequentialPlanner(kernel);

    var plan = await planner.CreatePlanAsync(query);

    Console.WriteLine("Plan:\n");
    Console.WriteLine(JsonSerializer.Serialize(plan, new JsonSerializerOptions { WriteIndented = true }));

    var result = await kernel.RunAsync(plan);

    Console.WriteLine(result);

    try
    {
        return Results.Json(JsonSerializer.Deserialize<Answer>(result.GetValue<string>()));
    }
    catch (System.Exception)
    {
        return Results.Json(new { answer = result.GetValue<string>() });
    }    

});


app.Run();