
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

var modelId = Environment.GetEnvironmentVariable("MODEL_ID")!;
var endpoint = Environment.GetEnvironmentVariable("ENDPOINT")!;
var apiKey = Environment.GetEnvironmentVariable("API_KEY")!;
var interpreterEndpoint = Environment.GetEnvironmentVariable("INTERPRETER_ENDPOINT")!;

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddTransient((p) =>
    {
#pragma warning disable SKEXP0050 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
        var httpClientFactory = p.GetRequiredService<IHttpClientFactory>();
        var settings = new SessionsPythonSettings(new Guid().ToString(), new Uri(interpreterEndpoint));
        var pythonPlugin = new SessionsPythonPlugin(settings, httpClientFactory, async () =>
        {
            var credential = new DefaultAzureCredential();
            var token = await credential.GetTokenAsync(new TokenRequestContext(["https://dynamicsessions.io/.default"]));
            return token.Token;
        });

        var kernelBuilder = Kernel.CreateBuilder();
        kernelBuilder.Services.AddLogging(c => c.SetMinimumLevel(LogLevel.Trace).AddDebug());
        kernelBuilder.Services.AddAzureOpenAIChatCompletion(modelId, endpoint, apiKey);
        kernelBuilder.Plugins.AddFromObject(pythonPlugin);
        return kernelBuilder.Build();
#pragma warning restore SKEXP0050
    });

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/runcode", async (Kernel kernel) =>
{
#pragma warning disable SKEXP0060 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
    var code = "print('Hello World from Python!')";
    var planner = new HandlebarsPlanner(new HandlebarsPlannerOptions() { AllowLoops = false });
    var plan = await planner.CreatePlanAsync(kernel, $"Execute the following code: *** {code} *** in Python and return the output.",
        new() {
            { "code", code }
        });

    // Execute the plan
    var result = (await plan.InvokeAsync(kernel, new() {
                        { "code", code }
                    })).Trim();

    return result;
#pragma warning restore SKEXP0060
})
.WithName("RunCode")
.WithOpenApi();

app.Run();
