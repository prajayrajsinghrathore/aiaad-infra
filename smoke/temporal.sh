#!/usr/bin/env bash
set -eo pipefail

echo "Running Temporal smoke test..."

# We use an ephemeral pod with the temporal CLI to test connection to the temporal frontend
kubectl run temporal-smoke-test --rm -i --tty --image=temporalio/temporal:1.8.2 -n aiaad-infra --restart=Never -- \
  operator namespace create --address aiaad-temporal-frontend.aiaad-infra.svc.cluster.local:7233 aiaad-hackathon || echo "Namespace may already exist"

kubectl run temporal-smoke-test --rm -i --tty --image=temporalio/temporal:1.8.2 -n aiaad-infra --restart=Never -- \
  operator namespace list --address aiaad-temporal-frontend.aiaad-infra.svc.cluster.local:7233 | grep aiaad-hackathon

echo "Temporal smoke test completed successfully."
