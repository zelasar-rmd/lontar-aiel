# 📜 Implementation Plan: Lontar AIEL Telemetry

> **Product Name:** Lontar AI Emission Ledger (Lontar AIEL)  
> **Document Version:** `v0.1.0-alpha`  
> **Date:** September 18, 2026  
> **Target Repository:** [`zelasar-rmd/lontar-aiel`](https://github.com/zelasar-rmd/lontar-aiel) (Branch: `telemetry`)  
> **Alignment:** Aligned with [`PRD.md`](PRD.md) and [`PROJECT_SCOPE.md`](PROJECT_SCOPE.md)  

---

## 1. Designated Telemetry Storage Repository

**Target Repository:** `zelasar-rmd/lontar-aiel`  
**Target Branch:** `telemetry` (Orphan audit ledger branch)

### Why this is the designated choice:
- **Clean Separation of Concerns:** Keeps operational telemetry logs completely isolated from main source code.
- **Living Proof of Concept:** Makes `zelasar-rmd/lontar-aiel` a self-referential public demonstration repository—an open-source project that transparently audits and publishes its own AI computational footprint!
- **Zero Impact on Master Code:** Telemetry commits are pushed strictly to the `telemetry` branch, keeping the `main` branch 100% clean.

---

## 2. Iterative Calculation Methodology (v0.1.0-alpha Baseline)

> ⚠️ **Scientific Disclaimer:** Mathematical formulas and baseline coefficients are active alpha estimates. Accuracy will be continuously iterated and improved based on empirical benchmarking, peer-reviewed literature (e.g., Shaolei Ren's WUE research, CodeCarbon), and regional grid intensity APIs.

### Current Alpha Coefficients:
- **Energy ($E$):**
  $$\text{Energy (Wh)} = \left( \frac{\text{Total Tokens}}{1000} \right) \times K_{\text{model}}$$
  * $K_{\text{Flash}}$ (Gemini 3.8 Flash, Claude Haiku): `0.20 Wh / 1,000 tokens`
  * $K_{\text{Pro}}$ (Gemini Pro, Claude Sonnet, GPT-4o): `1.50 Wh / 1,000 tokens`
- **Carbon Footprint ($C$):** $\text{Energy (Wh)} \times 0.40\text{ gCO}_2\text{e/Wh}$ (Global cloud datacenter average).
- **Cooling Water ($W$):** $\frac{\text{Tokens}}{1000} \times 0.50\text{ mL}$ (WUE baseline).
- **Tree Sequestration ($T$):** $\frac{\text{Carbon (g)}}{0.04185}$ (Minutes of mature tropical tree absorption).

---

## 3. Telemetry Pipeline Architecture (Termux Local Server)

```text
  [ AI Session Concludes ]
                 │
                 ▼
┌─────────────────────────────────┐
│ 1. Local Termux Cron Server     │  (Runs automatically every night at 23:00 via crond)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 2. Elixir Stream Audit Engine   │  (Parses daily transcript.jsonl in < 2ms)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 3. Log Appender (JSONL Format)  │  (Writes record to telemetry/logs/YYYY-MM.jsonl)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 4. Git Auto-Commit & Push       │  (Pushes quietly to zelasar-rmd/lontar-aiel telemetry branch)
└─────────────────────────────────┘
```

---

## 4. Standard Telemetry Log Schema (`telemetry/logs/2026-09.jsonl`)

Each line in the target log represents a complete, privacy-sanitized session receipt (strictly aggregate metrics, **no raw prompt text**):

```json
{
  "timestamp": "2026-09-18T01:35:00Z",
  "session_id": "1823b289-bdd4-4f11-aaea-6801c38c7b99",
  "model": "Gemini 3.6 Flash",
  "turn_count": 8,
  "total_tokens": 18200,
  "energy_wh": 3.64,
  "co2_grams": 1.46,
  "water_ml": 9.10,
  "tree_mins": 34.9,
  "git_commit_hash": "a1b2c3d4",
  "version": "v0.1.0-alpha"
}
```

---

## 5. Step-by-Step Implementation Roadmap

### Step 1: Initialize Telemetry Branch in `zelasar-rmd/lontar-aiel`
1. Create an isolated orphan branch in the repository:
   ```bash
   cd /tmp/lontar-aiel
   git checkout --orphan telemetry
   git rm -rf .
   mkdir -p logs
   echo "# Lontar AIEL Public Telemetry Ledger" > README.md
   git add README.md
   git commit -m "chore: initialize telemetry ledger branch v0.1.0-alpha"
   git push origin telemetry
   git checkout main
   ```

### Step 2: Configure Local Termux Background Cron Server
1. Install scheduling packages and acquire background execution lock:
   ```bash
   pkg install cronie termux-api -y
   termux-wake-lock
   ```

2. Register the nightly cron entry (`crontab -e`):
   ```cron
   # Run Lontar AIEL telemetry audit and Git push every night at 23:00
   0 23 * * * /data/data/com.termux/files/home/AGY/.agents/skills/session-emission-tracker/scripts/sync_telemetry.sh >> ~/.lontar_cron.log 2>&1
   ```

3. Ensure `crond` starts automatically when Termux opens:
   Add `crond` check to `~/.bashrc` or `~/.zshrc`:
   ```bash
   pgrep crond > /dev/null || crond
   ```

### Step 3: Create Automation Script (`sync_telemetry.sh`)
Create zero-token terminal utility `scripts/sync_telemetry.sh` in `lontar-aiel`:

```bash
#!/usr/bin/env bash
# Termux Automated Telemetry Exporter & Git Push (v0.1.0-alpha)

TRANSCRIPT_DIR="${HOME}/.gemini/antigravity-cli/brain"
LONTAR_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Find transcripts modified in the last 24 hours
find "$TRANSCRIPT_DIR" -name "transcript.jsonl" -mtime -1 2>/dev/null | while read -r transcript; do
  echo "📊 Auditing: $transcript"
  
  # Run Elixir engine to extract JSON payload
  JSON_PAYLOAD=$(elixir "$LONTAR_REPO_DIR/scripts/calculate_emission.exs" "$transcript" --json 2>/dev/null)
  
  if [ -n "$JSON_PAYLOAD" ]; then
    MONTH=$(date +"%Y-%m")
    
    # Push quietly to telemetry branch
    cd "$LONTAR_REPO_DIR" || exit
    git checkout telemetry --quiet
    mkdir -p logs
    echo "$JSON_PAYLOAD" >> "logs/$MONTH.jsonl"
    git add logs/
    git commit -m "telemetry: daily audit $(date +'%Y-%m-%d')" --quiet
    git push origin telemetry --quiet
    git checkout main --quiet
  fi
done
```
