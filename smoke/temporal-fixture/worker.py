import asyncio
import sys
from temporalio import workflow
from temporalio.client import Client
from temporalio.worker import Worker

@workflow.defn
class SmokeWorkflow:
    def __init__(self) -> None:
        self.is_completed = False

    @workflow.run
    async def run(self) -> str:
        # Wait until the completion signal is received
        await workflow.wait_condition(lambda: self.is_completed)
        return "Workflow completed successfully after signal!"

    @workflow.signal
    def complete_signal(self) -> None:
        self.is_completed = True

async def main():
    target_address = "aiaad-temporal-frontend.aiaad-infra.svc.cluster.local:7233"
    client = await Client.connect(target_address, namespace="aiaad-hackathon")
    worker = Worker(
        client,
        task_queue="smoke-task-queue",
        workflows=[SmokeWorkflow],
    )
    print("Worker started. Press Ctrl+C to exit.")
    await worker.run()

if __name__ == "__main__":
    asyncio.run(main())
