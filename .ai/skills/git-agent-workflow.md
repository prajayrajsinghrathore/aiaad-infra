# Git and agent workflow
- Work from short-lived branches/worktrees: feat/INF-XX-slug.
- Rebase/merge current main before starting a new agent task.
- High-blast-radius files require senior review: AGENTS.md, .ai/skills/**, bootstrap/**, environments/**, shared Helm/base values, Istio resources.
- Keep PRs bounded to one INF work package or one clearly-reviewable subset.
- Agent must inspect existing repo first and extend it; never recreate the repo or move folders without explicit instruction.
