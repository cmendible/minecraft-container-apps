from dapr_agents import Agent, OpenAIChatClient
from dotenv import load_dotenv
import asyncio
import logging
import os
import sys
from dapr_agents.tool.mcp import MCPClient
from prompt import AGENT_SYSTEM_PROMPT
import chainlit as cl

load_dotenv()

@cl.on_chat_start
async def start():
    # Create the MCP client
    client = MCPClient()

    # Connect to MCP server using STDIO transport
    await client.connect_stdio(
        server_name="minecraft",
        command="npx",  # Use the current Python interpreter
        args=["../minecraft-mcp-server",
            "--host",
            os.getenv("MINECRAFT_SERVER"),
            "--username",
            "Vicky"],
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

    global agent
    # Create the Weather Agent using MCP tools
    agent = Agent(
        name="Vicky",
        role="Minecraft Assitant",
        goal="Help humans to play minecraft",
        instructions=[
            AGENT_SYSTEM_PROMPT
        ],
        tools=tools,
        llm=llm,
    )

    # sleep 3 seconds to ensure the agent is ready
    await asyncio.sleep(3)

@cl.on_message
async def main(message: cl.Message):
    # generate the result set and pass back to the user
    result = await agent.run(message.content)

    await cl.Message(
        content=result,
    ).send()
