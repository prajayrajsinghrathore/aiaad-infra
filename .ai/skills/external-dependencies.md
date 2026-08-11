# External dependencies
External, not self-hosted in aiaad-infra:
- Neo4j AuraDB Free/Trial.
- Azure AI Foundry/OpenAI.
- Azure DevOps.
- Microsoft Graph/SharePoint.
Infra validates network/DNS/TLS/identity/config paths only.
Do not implement application connector/domain logic here.
If connectivity is blocked by organisational firewall/mesh/permission, return BLOCKED with exact evidence; do not bypass controls.
Store only non-secret endpoint/config names in Git.
