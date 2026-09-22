# 📜 Lontar AI Emission Ledger (Lontar AIEL)

> **Transparent AI environmental footprint tracking, literacy, and sustainability engine.**

---

## 🌿 Why "Lontar"?

In Nusantara (Indonesian) heritage, **Lontar** refers to the ancient palm-leaf manuscripts used across centuries to record wisdom, laws, history, and scientific accounts with enduring permanence. 

**Lontar AIEL** revives this concept for the modern computational age: an immutable, transparent ledger recording the energy consumption, greenhouse gas emissions, and cooling water costs of artificial intelligence—bridging computation with ecological accountability.

---

## 🏛️ Core Capabilities

1. **Mandatory Response Footer Protocol:**
   Enforces a clean, standardized environmental impact summary on every AI conversation turn across IDEs, desktop applications, and terminal CLIs.
2. **Ultra-Fast Elixir BEAM Stream Engine:**
   Powered by the BEAM runtime (`calculate_emission.exs`), the engine stream-parses full session transcripts (`transcript.jsonl`) in sub-milliseconds with negligible memory footprint.
3. **Confluent Data Stream Real-Time Telemetry (v1.4.0-confluent):**
   Streams background telemetry receipts in real-time to Confluent Cloud Kafka via TLS 1.3 encrypted REST Proxy / OTLP HTTP protocols (`lontar_telemetry_daemon.exs`).
4. **Strict Zero-Prompt Retention & Privacy Protocol:**
   Guarantees that raw conversation text, prompts, source code, and outputs are **100% scrubbed locally** before any network event is generated.
5. **Multi-Node Machine Attribution:**
   Automatically distinguishes emissions across edge devices (**Termux / Android**, **Windows**, **macOS**, and **Linux**), displaying a consolidated multi-machine breakdown table.
6. **Scientific Grounding & Ecological Offsets:**
   Translates raw token counts into real-world resource footprints (Watt-hours, grams of $CO_2e$, milliliters of cooling water) linked to accredited conservation initiatives (*LindungiHutan* coastal mangrove restoration).

---

## 📋 The Standardized Footer Format

Whenever an AI agent completes a response under Lontar AIEL guidelines, it appends this standardized footprint:

```markdown
──────────────────────────────────────────────────────────────────────
🌱 Session & Environmental Footprint
• Tokens & Compute : Turn: ~1,250 | Session: ~16,500 tokens (Gemini 3.8 Flash)
• Energy & Power   : Turn: ~0.25 Wh | Session: ~3.30 Wh (~0.0033 kWh)
• Carbon Footprint : Turn: ~0.10 g | Session: ~1.32 g CO₂e
• Water & Offset   : ~8.25 mL cooling | ~31.5 min tree absorption
• Conservation     : LindungiHutan (Indonesian Coastal Mangrove Restoration)
──────────────────────────────────────────────────────────────────────
```

---

## 🚀 Quickstart & Universal CLI

### Universal `lontar` Command (Cross-Platform)

```bash
# 1. View aggregated multi-device ledger
lontar ledger

# 2. Audit current active conversation session
lontar audit

# 3. View only the latest turn delta
lontar audit --latest

# 4. Sync session receipts to Git telemetry branch
lontar sync
```

### Direct Elixir Engine Execution

```bash
# Dual report: Latest Turn Delta + Cumulative Session Total
elixir scripts/calculate_emission.exs

# Only the latest turn delta
elixir scripts/calculate_emission.exs --latest

# View aggregated ledger from Git telemetry branch
elixir scripts/calculate_emission.exs ledger

# Check engine version & options
elixir scripts/calculate_emission.exs --version
elixir scripts/calculate_emission.exs --help
```

---

## 📦 Cross-Platform Installation

### 🪟 Windows Setup
1. Install Erlang and Elixir:
   ```powershell
   winget install Erlang.Erlang
   winget install Elixir.Elixir
   ```
2. Clone repository:
   ```powershell
   git clone https://github.com/zelasar-rmd/lontar-aiel.git "$env:USERPROFILE\lontar-aiel"
   ```
3. Create the global `lontar` CLI wrapper in PowerShell:
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin"
   @'
   @echo off
   setlocal
   set "PATH=C:\Program Files\Erlang OTP\bin;%USERPROFILE%\scoop\apps\elixir\current\bin;%PATH%"
   set "ELIXIR_SCRIPT=%USERPROFILE%\lontar-aiel\scripts\calculate_emission.exs"
   set "SYNC_SCRIPT=%USERPROFILE%\lontar-aiel\scripts\sync_telemetry.sh"
   if exist "C:\Program Files\Git\bin\bash.exe" (set "BASH_EXE=C:\Program Files\Git\bin\bash.exe") else (set "BASH_EXE=bash")
   if "%~1"=="" goto help
   if "%~1"=="help" goto help
   if "%~1"=="version" (elixir "%ELIXIR_SCRIPT%" --version & goto end)
   if "%~1"=="ledger" (elixir "%ELIXIR_SCRIPT%" ledger & goto end)
   if "%~1"=="audit" (shift & elixir "%ELIXIR_SCRIPT%" %1 %2 %3 %4 %5 & goto end)
   if "%~1"=="sync" (shift & "%BASH_EXE%" "%SYNC_SCRIPT%" %1 %2 %3 %4 %5 & goto end)
   elixir "%ELIXIR_SCRIPT%" %*
   goto end
   :help
   echo Lontar AIEL Universal CLI v1.3.0
   echo Commands: lontar ledger, lontar audit, lontar sync, lontar version
   :end
   endlocal
   '@ | Set-Content -Path "$env:USERPROFILE\bin\lontar.bat"

   $p = [System.Environment]::GetEnvironmentVariable("Path", "User")
   if ($p -notlike "*$env:USERPROFILE\bin*") {
       [System.Environment]::SetEnvironmentVariable("Path", "$env:USERPROFILE\bin;$p", "User")
   }
   ```

### 📱 Termux (Android) Setup
```bash
pkg update && pkg install -y elixir git ncurses-utils
git clone https://github.com/zelasar-rmd/lontar-aiel.git ~/lontar-aiel
mkdir -p ~/bin
cat << 'EOF' > ~/bin/lontar
#!/usr/bin/env bash
LONTAR_DIR="${HOME}/lontar-aiel"
COMMAND="$1"
shift || true
case "$COMMAND" in
  ledger|logs) elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" ledger "$@" ;;
  audit|calc)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$@" ;;
  sync|push)   bash "${LONTAR_DIR}/scripts/sync_telemetry.sh" "$@" ;;
  version|-v)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" --version ;;
  help|-h|"")  echo "Lontar AIEL CLI v1.3.0 (Termux)"; echo "Commands: lontar ledger, lontar audit, lontar sync" ;;
  *)           elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$COMMAND" "$@" ;;
esac
EOF
chmod +x ~/bin/lontar
grep -q 'export PATH="$HOME/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 🐧 Linux (Ubuntu / Debian / Arch / Fedora) Setup
```bash
# Ubuntu/Debian: sudo apt install -y elixir erlang git
# Arch Linux:    sudo pacman -S elixir git
# Fedora:        sudo dnf install -y elixir git
git clone https://github.com/zelasar-rmd/lontar-aiel.git ~/.local/share/lontar-aiel
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/lontar
#!/usr/bin/env bash
LONTAR_DIR="${HOME}/.local/share/lontar-aiel"
COMMAND="$1"
shift || true
case "$COMMAND" in
  ledger|logs) elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" ledger "$@" ;;
  audit|calc)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$@" ;;
  sync|push)   bash "${LONTAR_DIR}/scripts/sync_telemetry.sh" "$@" ;;
  version|-v)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" --version ;;
  help|-h|"")  echo "Lontar AIEL CLI v1.3.0 (Linux)"; echo "Commands: lontar ledger, lontar audit, lontar sync" ;;
  *)           elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$COMMAND" "$@" ;;
esac
EOF
chmod +x ~/.local/bin/lontar
```

### 🍎 macOS Setup
```bash
brew install elixir git
git clone https://github.com/zelasar-rmd/lontar-aiel.git ~/lontar-aiel
mkdir -p /usr/local/bin 2>/dev/null || mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/lontar
#!/usr/bin/env bash
LONTAR_DIR="${HOME}/lontar-aiel"
COMMAND="$1"
shift || true
case "$COMMAND" in
  ledger|logs) elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" ledger "$@" ;;
  audit|calc)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$@" ;;
  sync|push)   bash "${LONTAR_DIR}/scripts/sync_telemetry.sh" "$@" ;;
  version|-v)  elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" --version ;;
  help|-h|"")  echo "Lontar AIEL CLI v1.3.0 (macOS)"; echo "Commands: lontar ledger, lontar audit, lontar sync" ;;
  *)           elixir "${LONTAR_DIR}/scripts/calculate_emission.exs" "$COMMAND" "$@" ;;
esac
EOF
chmod +x ~/.local/bin/lontar
```

---

## 📁 Repository Structure

```text
lontar-aiel/
├── README.md                            # Project overview & philosophy
├── docs/
│   ├── PRD.md                           # Product Requirement Document (v0.1.0-alpha)
│   ├── PROJECT_SCOPE.md                 # Scope boundaries, deliverables & NFRs
│   ├── IMPLEMENTATION_PLAN.md           # Step-by-step telemetry pipeline plan
│   ├── ROADMAP.md                       # Comprehensive 4-phase evolution roadmap
│   └── SPECIFICATION.md                 # Scientific formulas, constants & offset math
├── rules/
│   └── session-emission-reporting.md   # Universal AI rule (v1.2.0)
└── scripts/
    ├── calculate_emission.exs           # Elixir stream transcript audit engine (v1.2.0)
    └── sync_telemetry.sh                # Automated Termux/Linux telemetry Git exporter
```

---

## 🗺️ Development Roadmap
See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full 4-phase development plan—from private local incubation to public Phoenix LiveView carbon literacy registry.

---

## 📄 License
Private Research & Development — All rights reserved.
