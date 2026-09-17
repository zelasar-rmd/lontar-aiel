# 📄 Product Requirement Document (PRD): Lontar AIEL

> **Product Name:** Lontar AI Emission Ledger (Lontar AIEL)  
> **Document Version:** `v0.1.0-alpha`  
> **Date:** September 18, 2026  
> **Target Repository:** [`zelasar-rmd/lontar-aiel`](https://github.com/zelasar-rmd/lontar-aiel)  
> **Status:** Alpha Specification  

---

## 1. Executive Summary & Product Vision

### 1.1 Vision Statement
To establish an immutable, transparent, and real-time environmental accounting ledger for artificial intelligence computations—converting abstract token usage into verifiable scientific metrics (Watt-hours, grams of $CO_2e$, evaporative cooling water) and connecting computational footprints directly to verified ecological restoration.

### 1.2 Core Problem
1. **The AI Energy Crisis:** Large Language Models (LLMs) require massive electrical energy and data center cooling water, yet developers and enterprises operate in total ecological blindness.
2. **Lack of Micro-Telemetry:** Cloud providers (Google Cloud, AWS, Azure) report macro annual corporate emissions, but provide zero turn-by-turn carbon visibility for individual API calls or developer sessions.
3. **Greenwashing in Offsets:** Traditional carbon offset markets suffer from double-counting and lack transparent verification.

### 1.3 Target Audience
- **Primary (Phase 1–2):** AI Developers, Engineers, and Prompt Architects using terminal CLIs, Cursor, Antigravity, and Claude Code.
- **Secondary (Phase 3–4):** Enterprise ESG compliance teams needing Scope 3 AI carbon reporting under EU AI Act and CSRD regulations.

---

## 2. Product Requirements & Feature Breakdown

| Feature ID | Feature Name | Priority | Description | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **FR-01** | Real-Time Chat Footer | `P0` (Must Have) | Injects standard footprint block at the end of every AI response turn. | Displays Turn Delta vs. Session Cumulative metrics accurately. |
| **FR-02** | Stream Audit Engine | `P0` (Must Have) | BEAM/Elixir script (`calculate_emission.exs`) to parse `transcript.jsonl` files in < 5ms. | Outputs clean human-readable report or machine-readable JSON (`--json`). |
| **FR-03** | Local Cron Server | `P1` (High) | Termux background cron job (`crond`) running nightly at 23:00. | Automatically scans last 24h transcripts and executes `sync_telemetry.sh`. |
| **FR-04** | Git Telemetry Branch | `P1` (High) | Dedicated `telemetry` branch in `zelasar-rmd/lontar-aiel`. | Accepts appended JSONL telemetry records without touching `main` branch code. |
| **FR-05** | Direct Offset Mapping | `P2` (Medium) | Maps carbon grams to accredited Indonesian blue-carbon initiatives (LindungiHutan). | Links users to verified mangrove/tree sequestration initiatives. |

---

## 3. System Architecture & Data Flow

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          LOCAL TERMUX ENVIRONMENT                      │
│                                                                        │
│  [ AI Agent Session ] ──► Stores ──► [ transcript.jsonl ]              │
│                                              │                         │
│                                     Nightly Cron (23:00)               │
│                                              │                         │
│                                              ▼                         │
│                              [ sync_telemetry.sh ]                     │
│                                              │                         │
│                                              ▼                         │
│                              [ calculate_emission.exs ]                │
└──────────────────────────────────────────────┬─────────────────────────┘
                                               │
                                       Pushes JSON Payload
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────┐
                        │      GITHUB: zelasar-rmd/lontar-aiel         │
                        │      (Branch: telemetry/logs/YYYY-MM.jsonl)  │
                        └──────────────────────────────────────────────┘
```

---

## 4. Non-Functional Requirements (NFRs)

- **Performance:** Stream parsing of a 10MB `transcript.jsonl` file must complete in $< 10\text{ milliseconds}$.
- **Zero Token Cost:** Automation tasks (cron, script execution, Git pushes) must spend $0$ additional LLM API tokens.
- **Privacy & Security:** Telemetry payloads must only contain aggregate metrics ($Wh$, $CO_2$, water, token counts) and git commit hashes. Raw prompt text and conversation content must **NEVER** be committed to the public Git ledger.
- **Reliability:** Background daemon must survive Android app restarts via `termux-wake-lock` and `.bashrc` process checks.
