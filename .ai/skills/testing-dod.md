# Infra testing and Definition of Done
- Do not claim DONE without executing the step's verification.
- Scripts/install must be idempotent where practical.
- Helm values/templates must render successfully before apply.
- Required components expose healthy/readiness state.
- Persistent components must survive normal pod restart.
- Missing required environment inputs -> BLOCKED, never guessed.
- Optional intentionally omitted components -> SKIPPED, not FAIL.
- Smoke output must not expose secrets.
- Report exact commands/tests and exit-criterion evidence.
