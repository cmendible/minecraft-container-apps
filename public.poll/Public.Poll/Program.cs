using Dapr;
using Dapr.Client;
using Microsoft.AspNetCore.ResponseCompression;
using BlazorSignalRApp.Hubs;
using Microsoft.AspNetCore.SignalR;
using Public.Poll.Client.Pages;
using Public.Poll.Components;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveWebAssemblyComponents();

builder.Services.AddDaprClient();

builder.Services.AddSignalR();

builder.Services.AddResponseCompression(opts =>
{
    opts.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(
        ["application/octet-stream"]);
});

var app = builder.Build();

app.UseCloudEvents();

app.MapSubscribeHandler();

// app.UseResponseCompression();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseWebAssemblyDebugging();
}
else
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveWebAssemblyRenderMode()
    .AddAdditionalAssemblies(typeof(Public.Poll.Client._Imports).Assembly);

app.MapHub<ChatHub>("/chathub");

app.MapPost("/message", [Topic("eventhubs", "chat")]
async (string message) =>
{
    Console.WriteLine("Incoming Message Received : " + message);
    IHubContext<ChatHub> hubContext = app.Services.GetRequiredService<IHubContext<ChatHub>>();
    await hubContext.Clients.All.SendAsync("ReceiveMessage", "minecraft", message);
});

app.Run();
