import asyncio
import sys
import argparse
from temporalio.client import Client

async def main():
    parser = argparse.ArgumentParser(description="Temporal Smoke Client")
    parser.add_argument("action", choices=["start", "signal"])
    parser.add_argument("--id", help="Workflow ID")
    args = parser.parse_args()

    target_address = "aiaad-temporal-frontend.aiaad-infra.svc.cluster.local:7233"
    client = await Client.connect(target_address, namespace="aiaad-hackathon")

    if args.action == "start":
        wf_id = args.id or "smoke-workflow-id"
        # Since we just want the workflow to start and wait, we use start_workflow
        handle = await client.start_workflow(
            "SmokeWorkflow",
            id=wf_id,
            task_queue="smoke-task-queue",
        )
        print(f"Workflow started with ID: {handle.id}")
    elif args.action == "signal":
        if not args.id:
            print("Must provide --id for signal")
            sys.exit(1)
        handle = client.get_workflow_handle(args.id)
        await handle.signal("complete_signal")
        print(f"Workflow {args.id} signaled.")
        # Wait for completion
        result = await handle.result()
        print(f"Workflow result: {result}")

if __name__ == "__main__":
    asyncio.run(main())
