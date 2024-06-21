using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

public class sk_hue_client
{

    public static string systemPrompt = """"
                You are a home assistant that can control lights.
                Before changing the lights, you may need to check their current state.
                Avoid telling the user numbers like the saturation, brightness, and hue; instead, use adjectives like 'bright' or 'dark'.
                Change the light to the colors from the user prompt. If there is more than one color, rotate between them.
                If there is a specific order of colors, please respect that order, even if there are repeated colors.
                """";

    public static async Task<String> RunPrompt(Kernel kernel, IChatCompletionService chatCompletionService, string userPrompt)
    {
        Console.WriteLine("Executing Prompt: " + userPrompt);
        string serverResponse = string.Empty;
        ChatHistory history = new();
        history.AddSystemMessage(systemPrompt.ToString());

        // Get the user's input
        history.AddUserMessage(userPrompt.ToString());

        // Generate the bot's response using the chat completion service
        var response = chatCompletionService.GetStreamingChatMessageContentsAsync(
        chatHistory: history,
        executionSettings: new OpenAIPromptExecutionSettings()
            {
                ToolCallBehavior = ToolCallBehavior.AutoInvokeKernelFunctions
            },
            kernel: kernel
        ).ConfigureAwait(false);

        // Stream the bot's response to the console
        await foreach (var message in response)
        {
            serverResponse += message.ToString();
        }
        history.AddAssistantMessage(serverResponse); 
        Console.WriteLine("Prompt Response: " + serverResponse);
        return serverResponse;
    }
}
