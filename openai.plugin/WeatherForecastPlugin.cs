using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.SemanticKernel.Planning.Handlebars;
using Models;

namespace OpenAI.Plugin
{
    public class WeatherForecastPlugin
    {
        private static readonly JsonSerializerOptions _jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        private readonly ILogger _logger;
        private readonly Kernel _kernel;

        public WeatherForecastPlugin(ILoggerFactory loggerFactory, Kernel kernel)
        {
            _logger = loggerFactory.CreateLogger<WeatherForecastPlugin>();
            _kernel = kernel;
        }

        [Function("Get weather forecast")]
        [OpenApiOperation(operationId: "WeatherForecastPlugin", tags: new[] { "WeatherForecastPlugin" }, Description = "Get weather forecast for a given location")]
        [OpenApiParameter("location", Description = "Variables to use when executing the specified function.", Required = true, In = ParameterLocation.Query)]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(ExecuteFunctionResponse), Description = "Returns the response from the AI.")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.BadRequest, contentType: "application/json", bodyType: typeof(ErrorResponse), Description = "Returned if the request body is invalid.")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.InternalServerError, contentType: "application/json", bodyType: typeof(ErrorResponse), Description = "Internal Server Error")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "plugins/forecast")] HttpRequestData req,
            FunctionContext executionContext)
        {
            _logger.LogInformation("Processing forecast request.");

            var location = req.Query["location"];
            if (string.IsNullOrEmpty(location))
            {
                return await CreateResponseAsync(req, HttpStatusCode.BadRequest, new ErrorResponse() { Message = "Invalid request. Missing location parameter" });
            }

            try
            {

#pragma warning disable SKEXP0060 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.
                var planner = new HandlebarsPlanner(new HandlebarsPlannerOptions() { AllowLoops = false });
                var plan = await planner.CreatePlanAsync(_kernel, $"Get 7 day weather forcaste for {location}",
                    new() {
                        { "input", location }
                    });
                this._logger.LogInformation("Plan: {Plan}", plan);

                // Execute the plan
                var result = (await plan.InvokeAsync(_kernel, new() {
                        { "input", location }
                    })).Trim();
#pragma warning restore SKEXP0060 // Type is for evaluation purposes only and is subject to change or removal in future updates. Suppress this diagnostic to proceed.

                return await CreateResponseAsync(
                                   req,
                                   HttpStatusCode.OK,
                                   new ExecuteFunctionResponse() { Response = result });

            }
            catch (Exception ex)
            {
                return await CreateResponseAsync(req, HttpStatusCode.BadRequest, new ErrorResponse() { Message = ex.Message });
            }
        }

        private static async Task<HttpResponseData> CreateResponseAsync(HttpRequestData requestData, HttpStatusCode statusCode, object responseBody)
        {      
            var responseData = requestData.CreateResponse(statusCode);
            await responseData.WriteAsJsonAsync(responseBody);
            return responseData;
        }
    }
}
