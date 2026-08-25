# Claude Usage Bar

[![Release](https://img.shields.io/github/v/release/tugrulcavus/claude-usage-bar?color=5b54e6)](https://github.com/tugrulcavus/claude-usage-bar/releases/latest)
[![Website](https://img.shields.io/badge/website-live-5b54e6)](https://tugrulcavus.github.io/claude-usage-bar/)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-1a1a1a)

macOS menu bar app that shows your Claude.ai plan usage — the **5-hour** and
**weekly** limit bars, the same numbers as Claude Code's `/usage` HUD.

**[Website & live demo → tugrulcavus.github.io/claude-usage-bar](https://tugrulcavus.github.io/claude-usage-bar/)**

## Install

**[Download ClaudeUsageBar.dmg →](https://github.com/tugrulcavus/claude-usage-bar/releases/latest/download/ClaudeUsageBar.dmg)**

Open it, drag the app onto Applications, launch it. The app is **signed with an Apple Developer ID and
notarized**, so it opens on a double-click — no Gatekeeper warning, no Terminal step. Universal build
(Apple Silicon & Intel), macOS 13+.

> **Requires Claude Code's command-line tool**, installed and signed in on that Mac at least once.
> Usage Bar reads the login `claude` stores in the Keychain; working only in the **Claude desktop app is
> not enough**, because it signs in with its own web session and leaves no login Usage Bar can read. Run
> `claude` once and you're done — from then on Usage Bar keeps that login fresh by itself and you never
> need a terminal again.

<details>
<summary>Other ways in</summary>

A `.zip` of the same build is on [Releases](https://github.com/tugrulcavus/claude-usage-bar/releases/latest).
There is also a one-line installer, which is what the in-app updater runs — it downloads the latest zip,
installs it to `/Applications` and opens it, and never uses `sudo`:

```bash
curl -fsSL https://raw.githubusercontent.com/tugrulcavus/claude-usage-bar/main/install.sh | bash
```

Builds before 0.9.0 were ad-hoc signed and needed `xattr -dr com.apple.quarantine` before first launch.
That is no longer necessary.

</details>

It's a **menu-bar app** — no Dock icon. Look top-right for the dual-bar gauge.

## Cost

**Free, and it never spends your Claude usage.** It reads only your usage *numbers* from Claude's API (a
metadata call), so it doesn't consume your 5-hour / weekly budget or cost money. Besides Claude's own
endpoint the app makes exactly two other calls, both once a day and both switchable off: it downloads a
small `latest.json` from this repo's GitHub release to see whether a newer build exists, and it adds +1
to an anonymous per-day install counter (see [Updates](#updates)). No account, no identifier, no
analytics SDK — nothing about you or your usage leaves the machine.

## Features

- **Custom dual-bar menu-bar glyph** that maps 1:1 onto Claude's two windows — top = 5-hour, bottom = weekly. Template (auto-tinted) by default; opt-in color mode lights up only when the tracked window crosses the warn threshold. Swappable styles: dual-bar, single-bar, ring, percent. Choose which window it tracks and optionally show `NN%`.
- **Pacing verdict** — a burn-rate line ("On pace" / "Over rate · ~2h to limit") plus a pacing-target tick in each meter showing where you *should* be by now.
- **Two meter cards** (5-hour + weekly) with severity color, big rounded monospaced %, and a real local-time reset countdown ("Resets 5:00 PM · in 4h").
- **Per-model weekly rows** (Opus / Sonnet) from the official data, collapsed by default and auto-hidden when absent.
- **Worsen-only notifications** at 50 / 75 / 90% (re-arm after reset, no spam).
- **Rate-limited manual refresh** (5/hour, then a countdown lock).

## Data source — your Claude Code login

**No token to paste, and off by default.** A fresh install reads **nothing** — no Keychain, no
network — until you press **Connect**. When you do, the app reads the OAuth token Claude Code
already stores in your macOS Keychain (the `Claude Code-credentials` item) and calls
`GET /api/oauth/usage` with it — the same request Claude Code makes for `/usage`, so the endpoint
accepts it. It reads the official `five_hour` / `seven_day` `utilization` + `resets_at`.

- First launch shows a **Connect** button; nothing is accessed until you click it.
- The read goes through macOS's own `security` tool — the same one Claude Code stores the item
  with — so since 0.8.5 there is normally **no Keychain prompt at all**, and updates don't
  re-ask. If macOS does ever ask, click **Always Allow** once. You can **Disconnect** any time in
  Settings.
- A pasted `claude setup-token` token does **not** work here — as of early 2026 Anthropic's
  endpoint rejects those for third-party use, which is why the app reads Claude Code's own
  session token instead.

### Keeping the login fresh

That access token lasts about **eight hours**, and only Claude Code renews it. This bites harder
than it sounds: the **Claude desktop app signs in with a claude.ai web session and never touches
this Keychain item**, so someone who works there — rather than in a terminal — can have a token
that has been dead for days. Terminal and the VS Code terminal are the same case as each other:
both run the `claude` CLI, and both refresh the item whenever they do.

So when the token has run out, Usage Bar runs **your own** `claude` CLI and lets Claude Code
renew its own login, with its own OAuth client, exactly as if you had typed the command yourself.
It first asks `claude auth status` whether you are signed in at all — if the answer is no, no
command can help and the app says so rather than spinning. Otherwise it runs `claude doctor`, a
read-only checkup that needs a working token and therefore makes Claude Code refresh one. That
takes about a second, opens no terminal, and spends no quota. Switch it off under **Settings →
Keep the login fresh automatically**.

Usage Bar deliberately does *not* spend the refresh token itself. That would mean presenting as
Anthropic's own OAuth client from a third-party app in order to mint new tokens — a different
thing from reading a token your Claude Code already holds. If the CLI isn't installed, the app
says so and asks you to run `claude` yourself; it can't sign in on your behalf.

Caveats: this endpoint is **undocumented**, and Anthropic's ToS restricts these OAuth tokens to
Claude Code / Claude.ai — using them from a third-party app is a **gray area**, so use at your
own discretion, and it may break if Anthropic tightens enforcement. It's **429-prone**, so the
app auto-polls no faster than every 3 min and the manual refresh is rate-limited. Reading usage
does **not** consume your plan's quota.

## Updates

Every fifteen minutes the app fetches `latest.json` from the repo's `meta` release. If it announces a newer
version, the popover shows an **Update available** card — one click quits the app, re-runs the same
installer a fresh install uses, and relaunches it. That file can also carry a short notice, which is
how a heads-up reaches copies that are already running.

Once a day the same pass bumps a public per-day counter by one (`abacus.jasoncameron.dev` — no account, no
payload), so "hits on 2026-07-25" is simply how many copies ran that day. That count is the only usage
signal that exists; nothing identifies a machine, and there is no server of mine anywhere.

Turn it off in **Settings → Updates**: no update banners, and your machine stops being counted.

## Notes

- Signed with a Developer ID and notarized; runs under the hardened runtime. Not sandboxed (it
  reaches the network to call Claude's usage endpoint, and reads the Claude Code Keychain item).
- No `~/.claude` file scanning; usage comes only from the OAuth endpoint using Claude Code's token.
- The only subprocesses it ever runs are `/usr/bin/security` (to read the login) and your own
  `claude` CLI (to have Claude Code renew it).

---

© Tuğrul Çavuş. All rights reserved. Not affiliated with, or endorsed by, Anthropic.
"Claude" is a trademark of Anthropic.
