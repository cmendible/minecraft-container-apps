from dapr_agents import OpenAIChatClient
from dapr_agents.workflow import WorkflowApp, workflow, task
from dapr.ext.workflow import DaprWorkflowContext
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()


# Define Workflow logic
@workflow(name="task_chain_workflow")
def task_chain_workflow(ctx: DaprWorkflowContext):
    character = yield ctx.call_activity(get_character)
    print(f"Character: {character}")
    line = yield ctx.call_activity(get_line, input={"character": character})
    print(f"Line: {line}")
    return line


@task(
    description="Pick a random character from Mincecraft and respond with the character's name only"
)
def get_character() -> str:
    pass


@task(
    description="What is a famous line by {character}",
)
def get_line(character: str) -> str:
    pass


if __name__ == "__main__":
    llm = OpenAIChatClient(
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION")
    )

    wfapp = WorkflowApp(
        llm=llm,
    )

    results = wfapp.run_and_monitor_workflow_sync(task_chain_workflow)
    print(f"Results: {results}")