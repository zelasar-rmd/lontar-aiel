# 📦 Lontar AIEL: Universal CLI Installation & Setup Guide

> **Document Version:** `v0.1.0-alpha.2026-09-22-19:00`  
> **Target Audience:** End-Users, AI Engineers, & Terminal Operators  
> **Platform Support:** Windows, Termux (Android), Linux, macOS  

---

## 🏛️ Executive Design Goal: Zero-Friction Onboarding

Lontar AIEL requires **ZERO complex server setup, zero database creation, and zero manual Kafka configuration** from end-users.

```text
  [ 1. One-Line Install ] ──► [ 2. lontar opt-in ] ──► [ 3. lontar ledger ]
  Downloads < 15MB binary     Accepts Privacy Terms    Views Real-Time Footprint
```

---

## 🚀 Quickstart Installation (By Operating System)

### 🪟 1. Windows (PowerShell)

Run this command in PowerShell (no admin privileges required):

```powershell
iwr -useb https://raw.githubusercontent.com/zelasar-rmd/lontar-aiel/confluent-alpha/scripts/install.ps1 | iex
```

*Or manual setup:*
```powershell
git clone https://github.com/zelasar-rmd/lontar-aiel.git "$env:USERPROFILE\lontar-aiel"
elixir "$env:USERPROFILE\lontar-aiel\scripts\calculate_emission.exs" opt-in
```

---

### 📱 2. Termux / Android

Open Termux and execute:

```bash
pkg update && pkg install -y elixir git ncurses-utils
git clone https://github.com/zelasar-rmd/lontar-aiel.git ~/lontar-aiel
mkdir -p ~/bin
cat << 'EOF' > ~/bin/lontar
#!/usr/bin/env bash
elixir "${HOME}/lontar-aiel/scripts/calculate_emission.exs" "$@"
EOF
chmod +x ~/bin/lontar
export PATH="$HOME/bin:$PATH"
lontar opt-in
```

---

### 🐧 3. Linux (Ubuntu / Debian / Arch / Fedora)

```bash
curl -sSL https://raw.githubusercontent.com/zelasar-rmd/lontar-aiel/confluent-alpha/scripts/install.sh | bash
```

---

### 🍎 4. macOS

```bash
brew install elixir git
git clone https://github.com/zelasar-rmd/lontar-aiel.git ~/.local/share/lontar-aiel
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/lontar
#!/usr/bin/env bash
elixir "${HOME}/.local/share/lontar-aiel/scripts/calculate_emission.exs" "$@"
EOF
chmod +x ~/.local/bin/lontar
lontar opt-in
```

---

## 🛠️ Step-by-Step User Workflow

### Step 1: Initialize & Review Privacy Terms
Users run a single command to review the Privacy Protocol:
```bash
lontar opt-in
```
* **What happens behind the scenes:**
  * Displays the Zero-Prompt Retention Guarantee.
  * Generates an anonymous device key (`user_anon_id`) in `~/.lontar/identity.json`.
  * Starts the lightweight background telemetry daemon (`lontar daemon`).

---

### Step 2: Check Real-Time Usage & Emission Ledger
Whenever users want to inspect their carbon, water, energy, or land footprint:
```bash
lontar ledger
```
* **Output Display:**
```text
──────────────────────────────────────────────────────────────────────────
📜 LONTAR AIEL TELEMETRY LEDGER (CONFLUENT DATA STREAM)
🕒 Latest Audit Entry   : 2026-09-22 19:15 UTC+07:00
──────────────────────────────────────────────────────────────────────────
🌐 Total Audited Sessions : 12 session(s)
📝 Cumulative Tokens     : 148,250 tokens
⚡ Total Energy Footprint : 29.650 Wh (0.02965 kWh)
💨 Total Carbon Footprint : 11.860 g CO₂e
💧 Total Cooling Water   : 74.12 mL
🌳 Total Tree Equivalent : ~283.4 minutes of tropical tree absorption
──────────────────────────────────────────────────────────────────────────
💻 MACHINE & DEVICE FOOTPRINT BREAKDOWN:
  🪟 WINDOWS    : 8 session(s) |     98,500 tok |   19.70 Wh |    7.88 g CO₂e
  📱 TERMUX     : 4 session(s) |     49,750 tok |    9.95 Wh |    3.98 g CO₂e
──────────────────────────────────────────────────────────────────────────
```

---

### Step 3: Ecological Offsets & Repayment (`lontar offset`)
To view actionable repayment and tree planting options:
```bash
lontar offset
```
* **Output Display:**
```text
──────────────────────────────────────────────────────────────────────────
🌿 LONTAR ECOLOGICAL OFFSET & REPAYMENT OPTIONS
──────────────────────────────────────────────────────────────────────────
Your cumulative carbon footprint of 11.86 g CO₂e is balanced by:
  1. 🌊 LindungiHutan Mangrove Seedling : 1 Seedling = 12,300 g CO₂e/year
     • Direct Action : Sponsor 1 Mangrove seedling in Coastal Java
     • Quick Link    : https://lindungihutan.com/sponsor/lontar-aiel
  2. 🪸 Coral Reef Restoration : 1 Micro-fragment buffering
──────────────────────────────────────────────────────────────────────────
```

---

### Step 4: System Status & Daemon Management
Check daemon health at any time:
```bash
lontar status
```

To stop background telemetry streaming:
```bash
lontar daemon stop
```

---

## 📦 Package Size & Dependency Technical Specs

| Package Metric | Specification |
| :--- | :--- |
| **Download Size** | **< 500 KB** (Script mode) / **~15 MB** (Standalone Burrito binary) |
| **Installed Disk Space** | **~18 MB** total |
| **RAM Footprint** | **~12 MB** idle memory consumption |
| **Native Dependencies** | **Zero C compilation needed** (uses Erlang BEAM `:inets` & `:ssl`) |
| **Network Overhead** | **< 1 KB** per telemetry sync event (JSON compressed) |
