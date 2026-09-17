# 🎯 Project Scope Document: Lontar AIEL

> **Product Name:** Lontar AI Emission Ledger (Lontar AIEL)  
> **Document Version:** `v0.1.0-alpha`  
> **Date:** September 18, 2026  
> **Target Repository:** [`zelasar-rmd/lontar-aiel`](https://github.com/zelasar-rmd/lontar-aiel)  
> **Status:** Alpha Specification  

---

## 1. Project Boundaries & Scope Matrix

### 🟢 In-Scope (Phase 1 – Phase 3)
- **Scientific Footprint Engine:** Elixir-based stream parser calculating energy ($Wh$), carbon ($gCO_2e$), cooling water ($mL$), and tree absorption minutes ($mins$).
- **Developer Footers:** Standardized markdown response footers attached to AI agent turns across Antigravity, CommandCode, and CLI platforms.
- **Local Termux/Linux Server Automation:** Nightly crond background daemon auditing local session transcripts and appending JSON receipts.
- **Public Git Telemetry Ledger:** Dedicated `telemetry` orphan branch on `zelasar-rmd/lontar-aiel` serving as a zero-cost, open-source audit ledger.
- **Multi-Model Coefficients:** Dynamic model recognition (Gemini 3.8 Flash/Pro, Claude Sonnet/Opus, GPT-4o, local Ollama).

### 🔴 Out-of-Scope (Deferred to Phase 4 / Web3 Expansion)
- Custom speculative crypto token ($LONTAR).
- Complex hardware-level GPU power sensor attachments (relying instead on peer-reviewed model coefficients).
- Paid cloud infrastructure hosting (all personal ops run zero-cost on local Termux server & GitHub).

---

## 2. Key Deliverables & Artifacts

1. **`calculate_emission.exs` v1.2.0:** High-performance Elixir script supporting standard human output and `--json` machine export.
2. **`sync_telemetry.sh`:** Automated shell runner for Termux/Linux environment.
3. **`telemetry` Git Branch:** Isolated orphan branch hosting `logs/YYYY-MM.jsonl` audit records.
4. **`session-emission-reporting.md` (Rule v1.2.0):** Universal AI agent response rule definition.

---

## 3. Execution Roadmap & Milestones

```text
[ Milestone 1: Local Engine & Specs ] ──► [ Milestone 2: Termux Cron Automation ] ──► [ Milestone 3: Public Git Telemetry Ledger ]
```

- **Milestone 1 (Iterative / Active):** Established initial alpha baseline calculation engine (v1.2.0) and AI agent rules. *Note: Mathematical formulas and coefficients (Wh/k-tokens, grid intensity, WUE) are currently baseline estimates requiring continuous iteration, empirical benchmarking, and peer-reviewed research updates.*
- **Milestone 2 (Current Target):** Create `sync_telemetry.sh`, configure Termux `crond`, and verify nightly background parsing.
- **Milestone 3 (Next Step):** Initialize `telemetry` orphan branch on `zelasar-rmd/lontar-aiel` and publish first live telemetry audit logs.

---

## 4. Scientific Calculation Rigor & Iteration Commitment

> ⚠️ **Important Alpha Disclaimer:** Current energy ($Wh$), carbon ($gCO_2e$), and water ($mL$) formulas are baseline alpha estimates derived from early academic literature and average cloud datacenter metrics.

### Continuous Improvement Directives:
1. **Iterative Model Refinement:** As hardware (e.g., NVIDIA H100/Blackwell, Google TPU v5e/v6) and model architectures (dense vs. MoE) evolve, energy coefficients ($Wh / 1000\text{ tokens}$) will be continuously updated based on empirical benchmarking.
2. **Peer-Reviewed Scientific Grounding:** Transition baseline assumptions into rigorous peer-reviewed methodology (citing researchers like Shaolei Ren on WUE and HuggingFace/CodeCarbon research).
3. **Dynamic Regional Intensity:** Evolve static global carbon grid averages ($400\text{ gCO}_2\text{e/kWh}$) toward real-time grid carbon intensity APIs (e.g., ElectricityMaps / WattTime) based on datacenter region.
