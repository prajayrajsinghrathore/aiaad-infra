# Redis
- Redis is optional.
- Install only when a concrete approved consumer exists.
- Suitable uses: short-lived cache, rate-limit/concurrency coordination, transient locks where designed.
- Do not make canonical business correctness depend on Redis.
- If omitted, ensure no required app config references it.
- If installed, keep a small non-HA hackathon deployment and admin access private.
