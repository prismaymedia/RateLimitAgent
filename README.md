<div align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-brightgreen?logo=apple&style=flat-square" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift&style=flat-square" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/UI-SwiftUI-blue?logo=swift&style=flat-square" alt="SwiftUI"/>
  <img src="https://img.shields.io/github/license/prismaymedia/RateLimitAgent?style=flat-square" alt="MIT"/>
  <img src="https://img.shields.io/badge/contributions-welcome-brightgreen?style=flat-square" alt="Contributions Welcome"/>
  <br/>
  <img src="https://img.shields.io/badge/OpenCode-Community-8A2BE2?style=flat-square" alt="OpenCode Community"/>
  <img src="https://img.shields.io/github/v/release/prismaymedia/RateLimitAgent?style=flat-square" alt="Release"/>
  <img src="https://img.shields.io/badge/PRs-👀_welcome-8A2BE2?style=flat-square" alt="PRs Welcome"/>
</div>

<br/>

<p align="center">
  <b>RateLimitAgent</b> — A lightweight macOS menu bar utility that tracks rate limit resets for OpenCode's free AI models.<br/>
  Never get caught off guard by a 429 again.
</p>

---

## Overview

When you're using OpenCode's free models (`deepseek-v4-flash-free`, `nemotron-3-super-free`), hitting a rate limit mid-session is frustrating — especially when you have no idea when it'll reset.

**RateLimitAgent** lives in your macOS menu bar and shows a live countdown so you always know exactly when you can use the free models again.

<p align="center">
  <img src="docs/screenshots/popover.png" alt="RateLimitAgent Popover" width="480"/>
  <br/>
  <em>The menu bar countdown (left) and the popover with full details (right)</em>
</p>

---

## Features

| Feature | Description |
|---|---|
| 🕐 **Live Countdown** | `HH:MM:SS` timer in the menu bar — updates every second |
| 🔄 **Auto-Check** | Polls the API every 30 seconds with a minimal probe (1 token) |
| 🟢 **Status at a Glance** | Checkmark = available, Timer = rate-limited, Warning = error |
| 📊 **Progress Bar** | Visual indicator of how much cooldown time has elapsed |
| ⏰ **Exact Reset Time** | Tells you exactly when the rate limit expires |
| ⚡ **Zero Config** | No API key required — works out of the box |
| 🚫 **No Dock Icon** | Pure menu bar utility via `LSUIElement` |
| 📦 **Self-Contained** | No dependencies beyond SwiftUI + Foundation |

---

## Requirements

| Requirement | Version |
|---|---|
| **macOS** | 14.0 (Sonoma) or later |
| **Xcode / Swift** | Xcode 15+ or Swift 5.9+ CLI tools |
| **OpenCode** | Installed (this monitors its API) |

---

## Installation

### Option 1: Build from Source (recommended)

```bash
git clone https://github.com/prismaymedia/RateLimitAgent.git
cd RateLimitAgent
bash create-app.sh
open build/RateLimitAgent.app
```

Then add it to your **Login Items** (System Settings → General → Login Items) for auto-start.

### Option 2: Pre-built Binary

> Coming in the first [Release](https://github.com/prismaymedia/RateLimitAgent/releases). Download the `.app` zip, extract, and move to `/Applications`.

### Option 3: Homebrew (future)

```bash
# Once accepted into a tap:
brew install --cask rate-limit-agent
```

---

## Usage

1. **Launch** the app — it appears in the top-right menu bar
2. **Read the icon**:
   - ✅ **Checkmark** → free model is available
   - ⏱️ **Timer + countdown** → rate-limited, shows remaining cooldown
   - ⚠️ **Warning** → error contacting the API (hover to see details)
3. **Click the icon** → popover with full details:
   - Model name
   - Status badge
   - Live countdown with progress bar
   - Exact reset time
   - **"Check Now"** button for immediate re-check
4. **Auto-refresh** happens every 30 seconds

---

## How It Works

OpenCode's free models are rate-limited at the API level. When you exceed the limit:

```
┌─────────────┐     POST /zen/v1/chat/completions      ┌──────────────┐
│ RateLimit   │ ───────────────────────────────────────►│ OpenCode     │
│ Agent       │   {model: "deepseek-v4-flash-free",     │ API          │
│ (Menu Bar)  │    messages: [...], max_tokens: 1}      │              │
│             │ ◄───────────────────────────────────────│              │
└─────────────┘     200 → Not rate limited              └──────────────┘
                     429 + Retry-After: 3600 → Countdown
```

1. The app sends a **minimal request** (1 token response) every 30 seconds
2. If the API returns **HTTP 429**, it parses the `Retry-After` header
3. A **live countdown** starts in the menu bar
4. When the timer reaches **zero**, the app automatically re-checks
5. Once the model is available again, the icon switches back to a checkmark

The probe consumes almost nothing — 1 output token per check — so it has a negligible impact on your quota.

---

## Configuration

### Changing the Model

The app defaults to `deepseek-v4-flash-free`. To monitor a different model:

1. Quit the app
2. Open `Sources/RateLimitAgent/RateLimitStore.swift`
3. Change the `modelName` parameter default
4. Rebuild with `bash create-app.sh`

More flexible configuration (via settings UI or config file) is planned.

---

## Project Structure

```
RateLimitAgent/
├── Package.swift                        # SwiftPM manifest (macOS 14+)
├── create-app.sh                        # Build + .app bundle creation
├── Sources/
│   └── RateLimitAgent/
│       ├── RateLimitAgentApp.swift       # @main entry, MenuBarExtra, all UI
│       ├── RateLimitStore.swift          # Observable state, polling, countdown
│       └── RateLimitChecker.swift        # URLSession client for OpenCode API
├── build/
│   └── RateLimitAgent.app               # Generated bundle (after create-app.sh)
├── README.md
├── LICENSE                              # MIT
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
└── .gitignore
```

---

## Roadmap

- [x] Menu bar countdown timer
- [x] Auto-detect rate limit state via API probe
- [x] Open-source project structure (MIT)
- [ ] **Pre-built binary releases** with notarization
- [ ] **Multiple model monitoring** (check 2+ models simultaneously)
- [ ] **Preferences window** (model selection, custom refresh interval)
- [ ] **System notifications** when rate limit resets
- [ ] **Homebrew cask** for easy install
- [ ] **Menu bar icon customization** (SF Symbols picker)

---

## Contributing

Contributions are welcome and appreciated! See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

**Quick ideas for contributions:**
- Add support for monitoring multiple models simultaneously
- Add a preferences UI (SwiftUI Settings scene)
- Create a dark-mode friendly app icon
- Write unit tests for the rate limit parser
- Package it as a Homebrew cask

---

## Community

This project is made for the [OpenCode](https://opencode.ai) community. OpenCode is an open-source AI coding agent — check it out!

- [OpenCode on GitHub](https://github.com/anomalyco/opencode)
- [OpenCode Discord](https://opencode.ai/discord)

---

## License

[MIT](LICENSE) © 2026 Jonathan Lozano

---

<p align="center">
  <sub>Built with ❤️ for the OpenCode community. Not affiliated with OpenCode or anomalyco.</sub>
</p>
