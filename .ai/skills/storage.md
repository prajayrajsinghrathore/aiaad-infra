# Object storage
- Local developer environment may use MinIO.
- AKS deployment should prefer Azure Blob if available/approved.
- Infra owns environment configuration/connectivity/identity, not application object-store implementation.
- Use workload identity for Azure Blob.
- Do not deploy MinIO in AKS unless the team explicitly chooses it because Blob is unavailable or unsuitable.
- Never place source documents in Git.
