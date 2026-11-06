# Test log — 2026-11-06

Clean Linux container, Docker 29.9, Compose v2, 4 CPU / 15 GB RAM.

| Tool | Result | Evidence |
|------|--------|----------|
| linkedin-skills plugin | ✅ installed | `claude plugin install linkedin-skills@linkedin-skills` → v1.1.28 enabled |
| marketingskills plugin | ✅ installed | `marketing-skills@marketingskills` → v2.14.2 enabled |
| OpenOutreach plugin + CLI | ✅ installed | plugin v0.1.0 enabled; `openoutreach --help` runs |
| agency-agents | ✅ installed | 77 agent files in `.claude/agents/` |
| Harvey | ✅ installed | `harvey --help` runs from the venv |
| ScrapeGraphAI | ✅ installed (v2.3.1) | Python import OK. The Playwright browser download was blocked by the *test sandbox's* firewall (cdn.playwright.dev); it works on a normal machine |
| n8n | ✅ running | `/healthz` → `{"status":"ok"}` |
| Twenty | ✅ running | `/healthz` → ok, server + worker up |
| Cal.com | ✅ running | `/api/version` → 6.2.0 |
| Documenso | ✅ running | `/api/health` → database ok, certificate ok |
| Chatwoot | ✅ running | `/api` → v4.19.1, queue + data services ok |
| Invoice Ninja | ⚠️ config validated, not booted | Docker Hub returned `429 Too Many Requests` (anonymous pull limit of the test sandbox) |
| Plane | ⚠️ config validated, not booted | same Docker Hub 429 |
| Postiz | ⚠️ config validated, not booted | test sandbox could not reach ghcr.io |
| Meetily | — | desktop app, download link in README |

Bugs found and fixed during testing:
- n8n crash-looped with `address '::' is not available` on hosts without IPv6. Fixed with `N8N_LISTEN_ADDRESS=0.0.0.0`
- n8n now recommends Postgres 17, so its DB was moved to `postgres:17-alpine`
- `stack.env` values containing spaces broke `init`. They are now quoted
- one app failing to pull stopped `./stack.sh up` for every app after it. It now continues and lists the failures at the end
