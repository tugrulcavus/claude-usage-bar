#!/usr/bin/env bash
# Claude Usage Bar — one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/tugrulcavus/claude-usage-bar/main/install.sh | bash
#
# What it does: downloads the latest release, installs it to /Applications, and
# opens it — no dragging, no dialogs. It is also what the in-app updater runs,
# so there is only ever one install path to keep working.
#
# The app is signed with an Apple Developer ID and notarized, so Gatekeeper
# accepts it on its own; the quarantine flag is still cleared below purely so
# the very first launch is silent rather than showing the "downloaded from the
# internet" confirmation.
#
# It never uses sudo, touches only the app bundle, and you can read every line
# above before piping it to bash.
set -euo pipefail

REPO="tugrulcavus/claude-usage-bar"
APP="ClaudeUsageBar"
APP_DISPLAY="Claude Usage Bar"
BUNDLE_ID="com.tugrulcavus.claudeusagebar"

# ── pretty output ────────────────────────────────────────────────────────────
if [ -t 1 ]; then B=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; RED=$'\033[31m'; YEL=$'\033[33m'; R=$'\033[0m'; else B=""; DIM=""; GRN=""; RED=""; YEL=""; R=""; fi
say()  { printf '%s▸%s %s\n' "$B" "$R" "$*"; }
ok()   { printf '%s✓%s %s\n' "$GRN" "$R" "$*"; }
warn() { printf '%s!%s %s\n' "$YEL" "$R" "$*"; }
die()  { printf '%s✗ %s%s\n' "$RED" "$*" "$R" >&2; exit 1; }

# ── preflight ────────────────────────────────────────────────────────────────
[ "$(uname -s)" = "Darwin" ] || die "This installer is macOS only."
command -v curl >/dev/null 2>&1 || die "curl is required but not found."

TMP="$(mktemp -d "${TMPDIR:-/tmp}/cub-install.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ── resolve the latest release .zip asset ────────────────────────────────────
say "Finding the latest release…"
API="https://api.github.com/repos/$REPO/releases/latest"
API_JSON="$(curl -fsSL "$API")" || die "Couldn't reach GitHub — no network, or its API is rate-limiting this IP (60/hr unauthenticated). Try again shortly, or grab the .zip from https://github.com/$REPO/releases"
ASSET="$(printf '%s' "$API_JSON" \
  | grep -Eo '"browser_download_url":[[:space:]]*"[^"]*/'"$APP"'[^"/]*\.zip"' \
  | sed -E 's/.*"(https[^"]*)"/\1/' \
  | head -n1 || true)"
[ -n "$ASSET" ] || die "No $APP .zip in the latest release. Grab it manually from https://github.com/$REPO/releases"
# Sanity: only ever download a GitHub release asset (parsed from the authenticated API).
case "$ASSET" in
  https://github.com/*/releases/download/*) ;;
  *) die "Refusing to download from an unexpected URL: $ASSET" ;;
esac

# ── download ─────────────────────────────────────────────────────────────────
ZIP="$TMP/app.zip"
say "Downloading ${DIM}$(basename "$ASSET")${R}"
curl -fL# "$ASSET" -o "$ZIP" || die "Download failed. Check your connection and retry."

# ── unpack ───────────────────────────────────────────────────────────────────
say "Unpacking…"
ditto -x -k "$ZIP" "$TMP/unpacked" 2>/dev/null || die "Could not unzip the download."
SRC="$(/usr/bin/find "$TMP/unpacked" -maxdepth 4 -name "$APP.app" -type d -print -quit)"
[ -n "$SRC" ] || die "Downloaded archive did not contain $APP.app."

# ── strip Gatekeeper quarantine BEFORE first launch (the whole point) ─────────
say "Clearing the download flag so the first launch is silent…"
xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true
xattr -cr "$SRC" 2>/dev/null || true

# ── choose install dir (fall back to ~/Applications if /Applications is RO) ───
DEST_DIR="/Applications"
if [ ! -w "$DEST_DIR" ]; then
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
  warn "/Applications isn't writable; installing to ~/Applications instead."
fi
DEST="$DEST_DIR/$APP.app"

# ── replace any existing copy (quit it first so the move is clean) ───────────
# Quit by bundle id, never by name: `tell application "Claude Usage Bar"` does
# not resolve (that string is only CFBundleDisplayName; AppleScript matches
# CFBundleName, "ClaudeUsageBar") yet osascript still exits 0, so the old
# `|| pkill` fallback never fired. The old copy kept running on a deleted
# binary, `open` re-activated it instead of the new build, and the in-app
# updater sat on "Updating…" for good. The exit code is not evidence here:
# poll until the process is actually gone, then escalate.
if pgrep -x "$APP" >/dev/null 2>&1; then
  say "Quitting the running copy…"
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  for _ in $(seq 10); do
    pgrep -x "$APP" >/dev/null 2>&1 || break
    sleep 0.5
  done
  if pgrep -x "$APP" >/dev/null 2>&1; then
    pkill -x "$APP" 2>/dev/null || true
    sleep 1
    pkill -9 -x "$APP" 2>/dev/null || true
  fi
fi
if [ -d "$DEST" ]; then
  say "Removing the old version…"
  rm -rf "$DEST" || die "Couldn't remove $DEST (is it running?). Quit it and retry."
fi

# ── install ──────────────────────────────────────────────────────────────────
say "Installing to ${DIM}$DEST_DIR${R}"
ditto "$SRC" "$DEST" || die "Couldn't copy the app into $DEST_DIR."
xattr -cr "$DEST" 2>/dev/null || true

# ── launch ───────────────────────────────────────────────────────────────────
open "$DEST" || warn "Installed, but couldn't auto-launch. Open it from $DEST_DIR."

echo
ok "$APP_DISPLAY is installed and running."
printf '%s' "$DIM"
cat <<EOF
It's a menu-bar app — no Dock icon, no window. Look at the TOP-RIGHT of your
screen for the small dual-bar gauge. Click it for your Claude usage; the gear
opens Settings (data source, icon style, open-at-login).
EOF
printf '%s' "$R"
