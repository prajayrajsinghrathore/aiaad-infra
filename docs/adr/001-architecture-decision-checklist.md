# ADR 001: Architecture Decision Checklist

This checklist must be reviewed before making any architectural additions or edits to the `aiaad-infra` repository.

## Pre-Implementation Verification
- [ ] Read `AGENTS.md` and the relevant `.ai/skills/*.md` files.
- [ ] Inspect existing resources in the target environment (e.g. Storage classes) to avoid resource recreation or conflicts.
- [ ] Ensure that no new infrastructure tools (e.g. database engines, ingress controllers) are introduced without explicit architecture approval.
- [ ] Verify that no secrets, tokens, or credentials are hardcoded or committed.

## Naming and Structure Conventions
- [ ] Use exactly the two allowed namespaces: `aiaad-infra` and `aiaad-platform`.
- [ ] Ensure all Kubernetes resources and Helm releases use lowercase kebab-case.
- [ ] Keep target-specific properties (UAMIs, gateway refs, DNS hosts) mapped into environment-specific files under `environments/`.

## Quality and Verification
- [ ] All installation and bootstrap paths must be fully idempotent.
- [ ] Dry-run/template linting of Helm values is executed before applying configuration.
- [ ] Smoke tests and connectivity diagnostics are verified and execute successfully.
