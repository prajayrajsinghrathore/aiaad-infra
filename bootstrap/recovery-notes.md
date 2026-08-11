# Infrastructure Recovery & Teardown Notes

## Teardown Protocol
The `destroy-hackathon.sh` and `destroy-hackathon.ps1` scripts provide a scoped, dry-run-first teardown of the infrastructure.
By default, executing these scripts without flags will output exactly what Helm releases and Persistent Volume Claims (PVCs) reside in the `aiaad-infra` namespace, simulating what would be deleted. 

**Execution:**
- **Dry-Run (Safe):** `./bootstrap/destroy-hackathon.ps1`
- **Destructive Execution:** `./bootstrap/destroy-hackathon.ps1 -Force`

## External Resource Protection
The teardown scripts are strictly scoped to the `aiaad-infra` and `aiaad-platform` Kubernetes namespaces. 
They intentionally **do not** interact with the Azure or Neo4j control planes. The following external resources are inherently protected from deletion:
- Azure AI Foundry and OpenAI deployments
- Neo4j Aura databases and data
- Azure DevOps configurations
- SharePoint document libraries
- Istio Ingress Gateway (`istio-system` namespace)

## Full Recovery Protocol
In the event of a total cluster teardown using the `-Force` flag, the environment can be fully recovered by returning to the deterministic bootstrap scripts:
1. Re-run `bootstrap/bootstrap.ps1`.
2. Ensure you recreate the missing Kubernetes Secrets (e.g. `aiaad-neo4j-credentials`, `aiaad-ado-credentials`) in the `aiaad-platform` namespace, as these are not tracked in Git.
3. Validate recovery by executing `smoke/run-all.ps1`.
