# Authoritative infrastructure version pins.
# Agents MUST NOT change these without an explicit human decision.

temporal:
  chartRepository: temporalio
  chartName: temporal
  chartVersion: "1.8.2"
  appVersion: null        # fill only after verified/selected
  namespace: aiaad-infra

postgres:
  image: dhi.io/postgres
  version: "18"
  variant: runtime

kafka:
  image: quay.io/strimzi/kafka
  version: "latest-kafka-4.1.1"
  mode: kraft
  replicas: 1

redis:
  image: dhi.io/redis
  version: "8-debian"
  chart:
    repository: oci://dhi.io/redis-chart
    version: "23.0.7"

pgadmin:
  image: dpage/pgadmin4
  enabled: true
  imageVersion: "9.17"

kowl:
  imageL: quay.io/cloudhut/kowl:v1.5.0
  ports:
      - "8082:8080"
  enabled: true
  environment:
      KAFKA_BROKERS: kafka:29092
      KAFKA_TLS_ENABLED: false
      KAFKA_SASL_ENABLED: false
  deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  chartVersion: null
  imageVersion: null

redisInsight:
  enabled: false
  imageVersion: null

minio:
  aksEnabled: true
  chartVersion: "5.4.0"
  imageVersion: null

keda:
  enabled: true
  chart:
    repository: "oci://dhi.io/keda-chart"
    version: "2.20.2"