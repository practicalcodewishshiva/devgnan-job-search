#!/usr/bin/env bash
# Installs the command-line / Python tools from the list, each the way its README says:
#   #01 Harvey        — autonomous cold-email sales agent (runs on your Claude subscription)
#   #02 OpenOutreach  — describe your product, it finds & emails fitting B2B leads
#   #03 ScrapeGraphAI — "tell it what you want from a site in plain English"
#
#   ./install-cli-tools.sh            install all three
#   ./install-cli-tools.sh harvey     install one (harvey | openoutreach | scrapegraphai)
#
# Everything goes under ~/business-tools (override with TOOLS_DIR=...).
set -euo pipefail

TOOLS_DIR="${TOOLS_DIR:-$HOME/business-tools}"
HARVEY_REPO="https://github.com/ethanplusai/harvey.git"
info() { echo "==> $*"; }
warn() { echo "warning: $*" >&2; }
die() { echo "error: $*" >&2; exit 1; }

pick_python() {
  # Harvey needs Python 3.11+; prefer the newest interpreter available.
  for p in python3.13 python3.12 python3.11 python3; do
    if command -v "$p" >/dev/null && "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'; then
      echo "$p"; return 0
    fi
  done
  die "Python 3.11+ is required (Ubuntu: sudo apt install python3.12 python3.12-venv; macOS: brew install python@3.13)"
}

ensure_uv() {
  command -v uv >/dev/null && return 0
  info "installing uv (Python tool installer) with pip --user"
  "$(pick_python)" -m pip install --user --quiet uv || die "could not install uv — see https://docs.astral.sh/uv/getting-started/installation/"
  export PATH="$HOME/.local/bin:$PATH"
  command -v uv >/dev/null || die "uv installed but not on PATH — add ~/.local/bin to PATH"
}

install_harvey() {
  local py dir="$TOOLS_DIR/harvey"
  py="$(pick_python)"
  command -v git >/dev/null || die "git is required"
  if [[ -d "$dir/.git" ]]; then info "harvey: updating $dir"; git -C "$dir" pull --ff-only
  else info "harvey: cloning into $dir"; git clone --depth 1 "$HARVEY_REPO" "$dir"; fi
  info "harvey: creating virtualenv + pip install -e ."
  "$py" -m venv "$dir/.venv"
  "$dir/.venv/bin/pip" install --quiet --upgrade pip
  "$dir/.venv/bin/pip" install --quiet -e "$dir"
  [[ -f "$dir/.env" ]] || cp "$dir/.env.example" "$dir/.env"
  command -v claude >/dev/null || warn "harvey: Claude Code CLI not found — install it and run 'claude login' (Harvey uses your Claude Pro/Max plan)"
  cat <<EOF
    Harvey installed. Next steps (from its README):
      cd $dir && source .venv/bin/activate
      \$EDITOR .env                          # mailbox + settings, each variable documented inline
      harvey train https://your-company.com  # learns your product
      harvey signals --confirm free          # choose what makes a good prospect
      harvey discover                        # find businesses (free source)
      harvey dashboard                       # http://127.0.0.1:5555
      harvey run                             # nothing is sent without your approval
    Or simply: cd $dir && claude   → say "set up Harvey for me"
EOF
}

install_openoutreach() {
  ensure_uv
  info "openoutreach: uv tool install openoutreach"
  uv tool install --upgrade openoutreach
  cat <<EOF
    OpenOutreach installed. Next steps:
      openoutreach init      # one-time onboarding (product + target market)
      openoutreach find 10   # ten qualified leads as CSV (free)
      openoutreach run 5     # find five leads and email them
    The Claude Code plugin is already enabled for this repo via .claude/settings.json.
EOF
}

install_scrapegraphai() {
  local py dir="$TOOLS_DIR/scrapegraphai"
  py="$(pick_python)"
  info "scrapegraphai: creating virtualenv in $dir"
  "$py" -m venv "$dir/.venv"
  "$dir/.venv/bin/pip" install --quiet --upgrade pip
  "$dir/.venv/bin/pip" install --quiet scrapegraphai
  info "scrapegraphai: installing the Playwright Chromium browser it uses to fetch pages"
  "$dir/.venv/bin/playwright" install chromium || warn "playwright browser install failed — on Linux try: $dir/.venv/bin/playwright install --with-deps chromium"
  cat <<EOF
    ScrapeGraphAI installed. Use it with:
      source $dir/.venv/bin/activate
      python business-stack/examples/scrape_leads.py https://example.com "List every company name and contact email"
    (needs an LLM: set OPENAI_API_KEY, or run a local model with Ollama — see the example)
EOF
}

mkdir -p "$TOOLS_DIR"
targets=("$@"); [[ ${#targets[@]} -eq 0 ]] && targets=(harvey openoutreach scrapegraphai)
for t in "${targets[@]}"; do
  case "$t" in
    harvey) install_harvey ;;
    openoutreach) install_openoutreach ;;
    scrapegraphai) install_scrapegraphai ;;
    *) die "unknown tool '$t' (harvey | openoutreach | scrapegraphai)" ;;
  esac
done
info "done."
