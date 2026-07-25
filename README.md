# Claude Usage Bar

[![Release](https://img.shields.io/github/v/release/tugrulcavus/claude-usage-bar?color=5b54e6)](https://github.com/tugrulcavus/claude-usage-bar/releases/latest)
[![Website](https://img.shields.io/badge/website-live-5b54e6)](https://tugrulcavus.github.io/claude-usage-bar/)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-1a1a1a)

macOS menu bar app that shows your Claude.ai plan usage — the **5-hour** and
**weekly** limit bars, the same numbers as Claude Code's `/usage` HUD.

**[Website & live demo → tugrulcavus.github.io/claude-usage-bar](https://tugrulcavus.github.io/claude-usage-bar/)**

## Install

**One line — nothing to drag:**

```bash
curl -fsSL https://raw.githubusercontent.com/tugrulcavus/claude-usage-bar/main/install.sh | bash
```

It downloads the latest universal build (Apple Silicon & Intel), clears the Gatekeeper quarantine flag,
installs to `/Applications`, and opens it. ([Read the script first](install.sh) if you like — it never
uses `sudo`.)

**Manual (advanced):** download the `.zip` from [Releases](https://github.com/tugrulcavus/claude-usage-bar/releases/latest),
drag `ClaudeUsageBar.app` to Applications, then run this **once — before first launch:**

```bash
xattr -dr com.apple.quarantine "/Applications/ClaudeUsageBar.app"
```

> **Why the Terminal step?** The app is **ad-hoc signed** (no paid Apple Developer account), so a
> *downloaded* copy is quarantined and macOS blocks it as *"…is damaged and can't be opened."* For ad-hoc
> apps the **"Open Anyway"** button never appears — clearing the quarantine flag is the actual fix. The
> one-liner does it for you.

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
- On connect, macOS asks whether the app may read the `Claude Code-credentials` Keychain item —
  click **Always Allow** so it can refresh silently. If you're not signed in to Claude Code, run
  `claude` in Terminal first, then hit **Re-check**. You can **Disconnect** any time in Settings.
- A pasted `claude setup-token` token does **not** work here — as of early 2026 Anthropic's
  endpoint rejects those for third-party use, which is why the app reads Claude Code's own
  session token instead.

Caveats: this endpoint is **undocumented**, and Anthropic's ToS restricts these OAuth tokens to
Claude Code / Claude.ai — using them from a third-party app is a **gray area**, so use at your
own discretion, and it may break if Anthropic tightens enforcement. It's **429-prone**, so the
app auto-polls no faster than every 3 min and the manual refresh is rate-limited. Reading usage
does **not** consume your plan's quota.

## Updates

Once a day the app fetches `latest.json` from the repo's `meta` release. If it announces a newer
version, the popover shows an **Update available** card — one click quits the app, re-runs the same
installer a fresh install uses, and relaunches it. That file can also carry a short notice, which is
how a heads-up reaches copies that are already running.

The same daily pass bumps a public per-day counter by one (`abacus.jasoncameron.dev` — no account, no
payload), so "hits on 2026-07-25" is simply how many copies ran that day. That count is the only usage
signal that exists; nothing identifies a machine, and there is no server of mine anywhere.

Turn it off in **Settings → Updates**: no update banners, and your machine stops being counted.

## Notes

- Not sandboxed (reaches the network to call Claude's usage endpoint, and reads the Claude Code
  Keychain item).
- No `~/.claude` file scanning; usage comes only from the OAuth endpoint using Claude Code's token.

---

© Tuğrul Çavuş. All rights reserved. Not affiliated with, or endorsed by, Anthropic.
"Claude" is a trademark of Anthropic.
