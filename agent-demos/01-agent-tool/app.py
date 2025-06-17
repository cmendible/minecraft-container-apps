from dapr_agents import Agent, OpenAIChatClient
from dotenv import load_dotenv
import asyncio
import logging
import os
import sys
from dapr_agents.tool.mcp import MCPClient

load_dotenv()

async def main():
    # Create the MCP client
    client = MCPClient()

    await client.connect_stdio(
        server_name="local",
        command=sys.executable,  # Use the current Python interpreter
        args=["tools.py"],  # Run tools.py directly
    )

    # Get available tools from the MCP instance
    tools = client.get_all_tools()
    print("🔧 Available tools:", [t.name for t in tools])

    llm = OpenAIChatClient(
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION")
    )

    agent = Agent(
        name="Manolo",
        role="Weather Assistant",
        goal="Assist Humans with weather related tasks.",
        instructions=[
            "Get accurate weather information",
            "From time to time, you can also jump after answering the weather question.",
        ],
        tools=tools,
        llm=llm,
    )

    # Run a sample query
    result = await agent.run("What is the weather in Mlaga and Madrid?")
    print(result)

    # Clean up resources
    await client.close()

if __name__ == "__main__":
    asyncio.run(main())
