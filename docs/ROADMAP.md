# Lontar AI Emission Ledger (Lontar AIEL): Development Roadmap

> **Vision:** A decentralized, transparent accounting ledger and carbon-literacy engine for the AI era. Educating users on the environmental cost of computation and channeling awareness into verified ecological conservation.

---

## Phase 1: Foundational Protocols & Core Engine (Current)
- [x] Standardize mandatory AI agent response footer specification (`rules/session-emission-reporting.md`).
- [x] Build zero-dependency Elixir stream parser for transcript log audits (`scripts/calculate_emission.exs`).
- [x] Integrate with Antigravity (`agy`), Antigravity 2.0, and CommandCode environments.
- [x] Establish initial baseline coefficients for Flash vs. Pro models.
- [x] Isolate into independent Git repository (`zelasar-rmd/lontar-aiel`).

---

## Phase 2: Literacy Framework & Carbon Intelligence
- [ ] **Multi-Provider Coefficient Table:** Expand dynamic parameter recognition for Anthropic (Claude), OpenAI, and local Ollama models.
- [ ] **Carbon Literacy Explanations:** Formulate relatable human comparisons (e.g., smartphone charging cycles, kilometers of EV transit, boiling water).
- [ ] **Conservation Initiative Verification:** Standardize structured metadata links to accredited blue carbon and reforestation partners (LindungiHutan, Coral Guardian, Katingan Mentaya).
- [ ] **CLI Polish:** Implement standalone binary build (`mix escript.build`) for non-Elixir host machines.

---

## Phase 3: Developer Tooling & Integrations
- [ ] **Universal Rule Adapters:** Provide ready-made setup snippets for:
  - Cursor (`.cursorrules`)
  - Claude Code (`CLAUDE.md`)
  - Windsurf / Cascade rules
  - GitHub Copilot instructions
- [ ] **CI/CD Carbon Check (GitHub Action):** A GitHub action that calculates the token and carbon cost of AI-assisted PR code generation.
- [ ] **Dynamic SVG Readme Badges:** Generate real-time shields for open-source repositories showing carbon awareness and offset status.

---

## Phase 4: Public Platform & Literacy Registry
- [ ] **Phoenix LiveView Public Dashboard:**
  - Real-time interactive UI hosted on Fly.io / Gigalixir.
  - User session upload & carbon ledger analytics.
  - Interactive "Offset Simulator" allowing users to fund tree planting or coral fragments directly.
- [ ] **API & Webhook Engine:** Ingest token telemetry from team workspaces and enterprise LLM gateways.
- [ ] **Community Open Source Launch:** Public GitHub release, documentation site, and social launch.
