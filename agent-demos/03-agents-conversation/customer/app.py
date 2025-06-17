from dapr_agents import AssistantAgent, OpenAIChatClient
from dotenv import load_dotenv
import asyncio
import logging
import os
import sys

AGENT_SYSTEM_PROMPT = """
You are a customer at a book shop. Speak concisely and clearly.
"""

async def main():
    try:

        llm = OpenAIChatClient(
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
            api_version=os.getenv("AZURE_OPENAI_API_VERSION")
        )
        
        agent = AssistantAgent(
            role="Customer",
            name="Carlitos",
            goal="Get information abou the book you just learn abut.",
            instructions=[
                AGENT_SYSTEM_PROMPT,
            ],
            message_bus_name="messagepubsub",
            state_store_name="workflowstatestore",
            state_key="workflow_state",
            agents_registry_store_name="agentstatestore",
            agents_registry_key="agents_registry",
            llm=llm,
        )

        await agent.start()
    except Exception as e:
        print(f"Error starting service: {e}")


if __name__ == "__main__":
    load_dotenv()

    logging.basicConfig(level=logging.INFO)

    asyncio.run(main())