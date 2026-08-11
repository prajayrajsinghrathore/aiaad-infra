# Admin Port-Forward Runbook

To securely manage the infrastructure services deployed in this cluster without exposing them to the public internet, operators must use `kubectl port-forward`. 

Public VirtualService routes must **never** be created for these tools.

## Prerequisites
- You must have `kubectl` configured with access to the cluster environment.
- You must have RBAC permissions to `port-forward` in the `aiaad-infra` namespace.

## Available Tools

The following helper scripts automatically forward local ports to the appropriate cluster services.
*Note: Some tools (pgAdmin, Kafka UI, RedisInsight) are optional and will only forward successfully if their respective Helm charts have been deployed.*

### Temporal UI
- **Script:** `./temporal-ui.sh`
- **Local Access:** `http://localhost:8080`
- **Purpose:** Monitor Temporal workflows, inspect task queues, and manage Temporal namespaces.

### pgAdmin (Optional)
- **Script:** `./pgadmin.sh`
- **Local Access:** `http://localhost:8081`
- **Purpose:** Connect to the `aiaad-postgres` cluster to run queries and manage schemas.

### Kafka UI (Optional)
- **Script:** `./kafka-ui.sh`
- **Local Access:** `http://localhost:8082`
- **Purpose:** Monitor Kafka topics, inspect messages, and manage consumer groups.

### RedisInsight (Optional)
- **Script:** `./redisinsight.sh`
- **Local Access:** `http://localhost:8083`
- **Purpose:** Inspect Redis cache keys, perform manual evictions, and monitor memory usage.
