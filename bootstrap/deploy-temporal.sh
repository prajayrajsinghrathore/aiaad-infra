#!/usr/bin/env bash
set -eo pipefail

echo "Deploying Temporal..."

helm repo add temporal https://go.temporal.io/helm-charts
helm repo update temporal

helm upgrade --install aiaad-temporal temporal/temporal \
    -f helm/temporal/values.base.yaml \
    -f helm/temporal/values.hackathon.yaml \
    -n aiaad-infra \
    --wait

echo "Temporal deployed successfully."
