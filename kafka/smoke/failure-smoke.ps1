$ErrorActionPreference = "Continue"
$namespace = "aiaad-infra"
$image = "quay.io/strimzi/kafka:latest-kafka-4.1.1"
$topic = "platform.domain.events"

Write-Host "Creating ephemeral Kafka client pod..."
kubectl run kafka-client-failure-test -n $namespace --image=$image --restart=Never -- sleep 3600 | Out-Null
kubectl wait --for=condition=ready pod/kafka-client-failure-test -n $namespace --timeout=60s | Out-Null

Write-Host "1. Verifying Kafka is currently UP..."
$msg = "up-message-$(Get-Date -UFormat %s)"
$upResult = kubectl exec -n $namespace kafka-client-failure-test -- bash -c "echo '$msg' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server aiaad-kafka:9092 --topic $topic --producer-property max.block.ms=3000" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Initial write failed, Kafka might already be down!"
} else {
    Write-Host "Initial write succeeded."
}

Write-Host "2. Simulating Kafka outage (Scaling StatefulSet to 0)..."
kubectl scale sts aiaad-kafka-controller -n $namespace --replicas=0 | Out-Null
# Wait a few seconds for pod to terminate
Start-Sleep -Seconds 10

Write-Host "3. Attempting to write while Kafka is DOWN..."
# This should fail gracefully because of max.block.ms=3000
$downMsg = "down-message-$(Get-Date -UFormat %s)"
$downResult = kubectl exec -n $namespace kafka-client-failure-test -- bash -c "echo '$downMsg' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server aiaad-kafka:9092 --topic $topic --request-required-acks all --producer-property max.block.ms=3000" 2>&1

if ($downResult -match "TimeoutException" -or $downResult -match "disconnected") {
    Write-Host "Kafka outage detected gracefully! Producer timed out or disconnected as expected."
    Write-Host "Error details: $downResult"
} else {
    Write-Warning "Producer succeeded unexpectedly while Kafka was scaled to 0 or returned an unknown error: $downResult"
}

Write-Host "4. Recovering Kafka (Scaling StatefulSet to 1)..."
kubectl scale sts aiaad-kafka-controller -n $namespace --replicas=1 | Out-Null
kubectl wait --for=condition=ready pod/aiaad-kafka-controller-0 -n $namespace --timeout=120s | Out-Null

Write-Host "5. Verifying Kafka is UP and recovered..."
$recoveryMsg = "recovery-message-$(Get-Date -UFormat %s)"
$recoveryResult = kubectl exec -n $namespace kafka-client-failure-test -- bash -c "echo '$recoveryMsg' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server aiaad-kafka:9092 --topic $topic --producer-property max.block.ms=3000" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Recovery write failed!"
} else {
    Write-Host "Recovery write succeeded! No destructive recovery needed."
}

Write-Host "Cleaning up ephemeral client..."
kubectl delete pod kafka-client-failure-test -n $namespace --force --grace-period=0 | Out-Null
Write-Host "Failure smoke test completed."
