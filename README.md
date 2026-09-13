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
2. **Ultra-Fast Elixir Stream Engine:**
   Powered by the BEAM runtime (`calculate_emission.exs`), the engine stream-parses full session transcripts (`transcript.jsonl`) in sub-milliseconds with negligible memory footprint.
3. **Scientific Grounding:**
   Translates raw token counts into real-world resource footprints (Watt-hours, grams of $CO_2e$, milliliters of evaporative cooling water).
4. **Actionable Ecological Offsets:**
   Connects digital carbon footprints directly to tangible conservation initiatives (tropical tree sequestration, Indonesian mangrove restoration, coral reef buffering).

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

## 🚀 Quickstart

### 1. Run the Elixir Calculation Engine
Audit any local Antigravity transcript:

```bash
# Dual report: Latest Turn Delta + Cumulative Session Total
elixir scripts/calculate_emission.exs

# Only the latest turn delta
elixir scripts/calculate_emission.exs --latest

# Or specify an exact transcript path
elixir scripts/calculate_emission.exs /path/to/transcript.jsonl
```

### 2. Check Engine Version & Options
```bash
elixir scripts/calculate_emission.exs --version
elixir scripts/calculate_emission.exs --help
```

---

## 📁 Repository Structure

```text
lontar-aiel/
├── README.md                            # Project overview & philosophy
├── docs/
│   ├── ROADMAP.md                       # Comprehensive 4-phase evolution roadmap
│   └── SPECIFICATION.md                 # Scientific formulas, constants & offset math
├── rules/
│   └── session-emission-reporting.md   # Universal AI rule (v1.1.0)
└── scripts/
    └── calculate_emission.exs           # Elixir stream transcript audit engine (v1.0.0)
```

---

## 🗺️ Development Roadmap
See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full 4-phase development plan—from private local incubation to public Phoenix LiveView carbon literacy registry.

---

## 📄 License
Private Research & Development — All rights reserved.
