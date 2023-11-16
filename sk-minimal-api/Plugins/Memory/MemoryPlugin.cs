using System.ComponentModel;
using System.Text.Json;
using Microsoft.KernelMemory;


namespace Plugins.MemoryPlugin;

public class MemoryKernel
{

    static Memory memory;

    public static void Init(string apiKey)
    {
        memory = new KernelMemoryBuilder()
                          .WithOpenAIDefaults(apiKey)
                         .BuildServerlessClient();

        LoadTextMemories();
        LoadDocs();
    }

    static async void LoadTextMemories()
    {
        await memory.ImportTextAsync("Carlos Mendible, Manuel Sánchez y Gisela Torres son los ponentes de esta charla", "charla");
        await memory.ImportTextAsync("Gisela fue MVP en 2010 y 2011 de Windows Azure 🤣", "gisela");
        await memory.ImportTextAsync("Carlos fue MVP del 2017 al 2021 de Developer Technologies y Azure (es el más viejo) 🤣", "carlos");
        await memory.ImportTextAsync("Manu es el único MVP en esta charla", "manu");

    }

    static async void LoadDocs()
    {
        await memory.ImportDocumentAsync("docs/Guia completa 2022.pdf", documentId: "doc001");
        await memory.ImportDocumentAsync("docs/Minecraft_la_guia_definitiva.pdf", documentId: "doc002");
    }


    [SKFunction, Description("Responde preguntas sobre Minecraft")]
    public static async Task<string> Minecraft(string ask)
    {
        var answer = await memory.AskAsync(ask);

        // Answer
        Console.WriteLine($"\nAnswer: {answer.Result}");

        // Sources
        foreach (var x in answer.RelevantSources)
        {
            Console.WriteLine($"  - {x.SourceName}  - {x.Link} [{x.Partitions.First().LastUpdate:D}]");
        }

        // return a json string with the answer and the sources
        return JsonSerializer.Serialize(new { answer = answer.Result, references = answer.RelevantSources.Select(x => x.SourceName) });
    }

    [SKFunction, Description("Responde preguntas sobre la charla y personas que imparten en esta charla")]
    public static async Task<string> Charla(string ask)
    {

        var answer = await memory.AskAsync(ask);

        // Answer
        Console.WriteLine($"\nAnswer: {answer.Result}");

        // Sources
        foreach (var x in answer.RelevantSources)
        {
            Console.WriteLine($"  - {x.SourceName}  - {x.Link} [{x.Partitions.First().LastUpdate:D}]");
        }

        // return a json string with the answer and the sources
        return JsonSerializer.Serialize(new { answer = answer.Result, references = answer.RelevantSources.Select(x => x.SourceName) });

    }
}