# kafka/smoke/smoke-test.ps1
$ErrorActionPreference = "Stop"
Write-Host "Running Kafka smoke test..."

# Wait a moment for things to settle if just deployed
Start-Sleep -Seconds 5

# 1. Produce a message
Write-Host "Producing a message to platform.domain.events..."
kubectl exec -n aiaad-infra aiaad-kafka-controller-0 -- bash -c "echo 'smoke-test-message' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server aiaad-kafka:9092 --topic platform.domain.events"

# 2. Consume the message
Write-Host "Consuming the message from platform.domain.events..."
$consumedMessage = kubectl exec -n aiaad-infra aiaad-kafka-controller-0 -- bash -c "/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server aiaad-kafka:9092 --topic platform.domain.events --partition 0 --from-beginning --max-messages 1 --timeout-ms 15000"

if ($consumedMessage -match "smoke-test-message") {
    Write-Host "Smoke test PASSED! Consumed message: $consumedMessage"
} else {
    throw "Smoke test FAILED! Did not consume expected message. Output: $consumedMessage"
}
