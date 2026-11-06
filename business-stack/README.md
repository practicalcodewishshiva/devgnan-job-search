# Business automation stack

Setup for all 15 tools from *"15 GitHub repos to automate your business"*. Each tool is
installed the way its own project recommends, and every part was test-installed before
being committed.

| #  | Job                         | Tool            | How it's installed here                                   | Where it runs                  |
|----|-----------------------------|-----------------|-----------------------------------------------------------|--------------------------------|
| 01 | Find customers              | Harvey          | `./install-cli-tools.sh harvey` (git clone + venv)          | your laptop/server, CLI + `:5555` dashboard |
| 02 | Message them on LinkedIn    | OpenOutreach    | `./install-cli-tools.sh openoutreach` + Claude Code plugin  | CLI, and inside Claude Code    |
| 03 | Pull leads from any website | ScrapeGraphAI   | `./install-cli-tools.sh scrapegraphai` (venv + Playwright)  | Python, `examples/scrape_leads.py` |
| 04 | Write LinkedIn posts        | linkedin-skills | Claude Code plugin, enabled in `../.claude/settings.json`  | inside Claude Code             |
| 05 | The rest of your marketing  | marketingskills | Claude Code plugin, enabled in `../.claude/settings.json`  | inside Claude Code             |
| 06 | Schedule every post         | Postiz          | `./stack.sh up postiz`                                      | http://localhost:4007          |
| 07 | Book calls                  | Cal.com         | `./stack.sh up calcom`                                      | http://localhost:3002          |
| 08 | Take meeting notes          | Meetily         | desktop app, download it (see below)                       | your Mac / Windows PC          |
| 09 | Get proposals signed        | Documenso       | `./stack.sh up documenso`                                   | http://localhost:3003          |
| 10 | Send invoices               | Invoice Ninja   | `./stack.sh up invoiceninja`                                | http://localhost:8081          |
| 11 | Keep every customer (CRM)   | Twenty          | `./stack.sh up twenty`                                      | http://localhost:3001          |
| 12 | Answer customer questions   | Chatwoot        | `./stack.sh up chatwoot`                                    | http://localhost:3004          |
| 13 | Track your team's work      | Plane           | `./stack.sh up plane`                                       | http://localhost:8082          |
| 14 | Connect all of it           | n8n             | `./stack.sh up n8n`                                         | http://localhost:5678          |
| 15 | A whole team                | agency-agents   | 77 sales/marketing/support/PM/finance/product agents copied into `../.claude/agents/` | inside Claude Code |

---

## 1. Claude Code skills & agents (#02, #04, #05, #15): already done

When you open this repo in Claude Code and trust the folder, it offers to install the
plugins listed in `.claude/settings.json`:

- `linkedin-skills@linkedin-skills`: 12 skills (post writer, comment drafter, humanizer, profile optimizer, ...)
- `marketing-skills@marketingskills`: 53 skills (CRO, copywriting, cold email, SEO, ads, pricing, ...)
- `openoutreach@openoutreach`: drives the OpenOutreach CLI from Claude

You can also install them by hand:

```
/plugin marketplace add sergebulaev/linkedin-skills
/plugin install linkedin-skills@linkedin-skills
/plugin marketplace add coreyhaines31/marketingskills
/plugin install marketing-skills@marketingskills
```

The agency-agents roster is plain files in `.claude/agents/`, so it works with no extra
step. Ask for an agent by name, e.g. *"Use the Outbound Strategist agent to plan my
first campaign"*. Only the business divisions (sales, marketing, support,
project-management, finance, product, paid-media) were installed. The full roster has
~280 agents, mostly engineering and game development. Add others with
`cp agency-agents/<division>/*.md .claude/agents/`.

## 2. Self-hosted apps (#06, #07, #09–#14): `stack.sh`

### Prerequisites
- A Linux server or laptop with **Docker** and the **Compose v2** plugin (`docker compose version`)
- `openssl`
- RAM: about **8 GB to run everything at once** (Plane, Postiz and Chatwoot are the heaviest).
  With 2–4 GB, run only the apps you need.

### Start
```bash
cd business-stack
./stack.sh init        # creates stack.env + random passwords/keys for every app
nano stack.env         # optional: public hostname, SMTP, ports
./stack.sh up          # everything   (or: ./stack.sh up n8n twenty calcom)
./stack.sh status      # health + URLs
```

First boot takes a few minutes while images download and databases migrate. Then open
each URL and **create your admin account immediately**. Every app except Invoice Ninja
makes the first person who signs up the owner.

| App | First login |
|-----|-------------|
| n8n, Twenty, Cal.com, Documenso, Postiz, Plane | Sign up in the browser. Plane: open `/god-mode` first to create the instance admin |
| Chatwoot | Sign-up is disabled by default. The first visit shows the "create super admin" screen |
| Invoice Ninja | Created automatically: email = `ADMIN_EMAIL` from `stack.env`, password = `ADMIN_PASSWORD` in `apps/invoiceninja/secrets.env` |

### Other commands
```bash
./stack.sh logs chatwoot      # follow logs of one app
./stack.sh down plane         # stop (data is kept in Docker volumes)
./stack.sh update             # pull newer images and restart
./stack.sh urls
```

### Where the config lives
- `stack.env`: your settings (git-ignored)
- `apps/<app>/secrets.env`: generated once, **never regenerate** (git-ignored). Changing
  these locks you out of encrypted data. Back them up.
- `apps/<app>/extra.env`: optional per-app keys you add yourself (git-ignored), e.g.
  Postiz social logins:
  ```
  # apps/postiz/extra.env
  LINKEDIN_CLIENT_ID=...
  LINKEDIN_CLIENT_SECRET=...
  X_API_KEY=...
  X_API_SECRET=...
  ```
  Then run `./stack.sh up postiz`. Every network Postiz supports is listed in its
  [docs](https://docs.postiz.com/providers).
- `apps/<app>/.env`: generated from the three files above on every `init`/`up`. Don't edit it.

### Putting it on the internet
By default every port is bound to `127.0.0.1`, so nothing is exposed. On a VPS, either:
- tunnel: `ssh -L 5678:localhost:5678 you@server`, or
- put a reverse proxy with HTTPS in front (Caddy is simplest). Give each app a subdomain,
  set e.g. `N8N_URL=https://n8n.example.com` and `PUBLIC_SCHEME=https` in `stack.env`,
  then run `./stack.sh up` again. Example `Caddyfile`:
  ```
  n8n.example.com      { reverse_proxy 127.0.0.1:5678 }
  crm.example.com      { reverse_proxy 127.0.0.1:3001 }
  cal.example.com      { reverse_proxy 127.0.0.1:3002 }
  sign.example.com     { reverse_proxy 127.0.0.1:3003 }
  chat.example.com     { reverse_proxy 127.0.0.1:3004 }
  social.example.com   { reverse_proxy 127.0.0.1:4007 }
  invoice.example.com  { reverse_proxy 127.0.0.1:8081 }
  plane.example.com    { reverse_proxy 127.0.0.1:8082 }
  ```
  Plane runs its own proxy and listens on all interfaces at `PLANE_PORT`, so firewall it.

### Email (SMTP)
Fill the `SMTP_*` lines in `stack.env` so apps can send invites, password resets, signing
requests and invoices. A Gmail/Workspace *app password* works for low volume. Use
Brevo/Resend/SES for more.

### Documenso signing certificate
`init` creates a self-signed certificate (`apps/documenso/cert.p12`) so signing works
straight away. For legally stronger signatures, replace it with a certificate from a CA
([Documenso docs](https://docs.documenso.com/developers/self-hosting/signing-certificate)),
keeping the passphrase in `secrets.env` in sync.

## 3. CLI tools (#01, #02, #03): `install-cli-tools.sh`

```bash
./install-cli-tools.sh                # all three, into ~/business-tools
./install-cli-tools.sh harvey         # or just one
```
Needs Python 3.11+ and git. Harvey also needs the Claude Code CLI logged in to a Pro/Max
plan (`claude login`), plus a sending mailbox on a separate domain. Read its README
section on deliverability before you send anything. The script prints each tool's next
steps when it finishes.

## 4. Meetily (#08): desktop app
Meetily records and transcribes meetings locally on your computer, so it is not a server app.
- **Windows:** download `x64-setup.exe` from <https://github.com/Zackriya-Solutions/meetily/releases/latest>
- **macOS (Apple Silicon):** download the `.dmg` from the same page
- **Linux:** build from source ([guide](https://github.com/Zackriya-Solutions/meetily/blob/main/docs/building_in_linux.md))

Only download from that GitHub releases page or meetily.ai. The project warns about fake copies.

## Wiring it together with n8n
Once the apps are up, n8n (#14) connects them. Useful first workflows:
1. **Cal.com booking → Twenty**: Cal.com webhook → create/update Person + Opportunity in Twenty.
2. **Documenso signed → Invoice Ninja**: Documenso webhook "document completed" → create invoice for that client.
3. **Chatwoot new conversation → Twenty**: create the contact in the CRM if it doesn't exist.
4. **Invoice Ninja paid → Plane**: open an onboarding issue for the new customer.

Each app has an API key screen in its settings. Paste the keys into n8n credentials.

## Tested
Validated in a clean Linux + Docker environment on 2026-11-06. The test results are in
`TESTED.md`.
