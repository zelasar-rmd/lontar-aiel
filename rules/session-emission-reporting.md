---
name: session-emission-reporting
version: 1.1.0
last_updated: 2026-09-12
status: active
scope: universal
engine_version: "1.0.0"
---

# Session Emission & Environmental Footprint Reporting (v1.1.0)

> **Version:** `1.1.0`  
> **Effective Date:** 2026-09-12  
> **Status:** Active (Production)  
> **Underlying Engine:** `session-emission-tracker` (`calculate_emission.exs` v1.0.0)

---

## 1. Mandatory Response Emission Summary (Unconditional)
At the conclusion of **EVERY response, question answer, implementation, code review, or conversation turn**, the agent MUST append a standardized environmental impact block in the response footer. This block is unconditional and must never be omitted regardless of task size.

### Standard Footer Format:
```markdown
──────────────────────────────────────────────────────────────────────
🌱 Session & Environmental Footprint
• Model & Tokens : ~<tokens> tokens (<model_name>)
• Energy & Power : ~<Wh> Wh (~<kWh> kWh)
• Carbon Impact  : ~<grams_co2> g CO₂e
• Water Cooling  : ~<mL> mL
• Green Offset   : ~<minutes_or_hours> of mature tropical tree absorption
• Conservation   : <Recommended initiative: Mangrove, Peatland, or Coral Reef>
──────────────────────────────────────────────────────────────────────
```

---

## 2. Standardized Calculation Coefficients (v1.0.0 Baseline)
To ensure instant, reliable reporting without slowing down responses, use the following scientific baseline metrics:

1. **Inference Energy Consumption:**
   - **Flash / Light Models** (e.g. Gemini 3.8 Flash): `0.20 Wh per 1,000 tokens`
   - **Pro / Frontier Models** (e.g. Gemini Pro, Claude 3.5/3.7 Sonnet): `1.50 Wh per 1,000 tokens`
2. **Grid Carbon Intensity:**
   - Global Cloud Datacenter Average: `400 g CO₂e per kWh` (or `0.40 g CO₂e per Wh`).
3. **Evaporative Water Footprint:**
   - Data Center Cooling (WUE): `0.50 mL per 1,000 tokens`.
4. **Sequestration & Offset Factors:**
   - 1 mature tropical tree sequesters ~`22 kg CO₂ / year` (~`60 g CO₂ / day` or ~`0.042 g CO₂ / minute`).
   - 1 Mangrove seedling absorbs ~`12.3 kg CO₂ / year` (~`4x` terrestrial soil density).
   - 1 Coral micro-fragment adoption supports ~`1 m²` of coastal biodiversity and reef buffering.

---

## 3. High-Integrity Green Initiatives Reference
When recommending conservation avenues in the footer or full audit:
- **Reforestation & Agroforestry:** [LindungiHutan](https://lindungihutan.com) (Indonesia), [Eden Reforestation Projects](https://www.edenprojects.org), [One Tree Planted](https://onetreeplanted.org).
- **Peatland & Mangrove Blue Carbon:** Katingan Mentaya Project (Central Kalimantan, Borneo), Wetlands International.
- **Marine & Coral Reef Restoration:** [Coral Guardian](https://coralguardian.org), Biorock Indonesia / Bali Coral Restoration, Coral Reef Alliance.

---

## 4. Deep Audits via Elixir Engine
When the user asks for a complete historical session audit, exact calculations, or cross-session trends:
- Route to the **`session-emission-tracker`** skill.
- Execute `skills/session-emission-tracker/scripts/calculate_emission.exs` against the session `transcript.jsonl`.

---

## 5. Version Changelog
- **v1.1.0 (2026-09-12):** Made emission footer mandatory on EVERY response (unconditional trigger) so all turns report footprint.
- **v1.0.0 (2026-09-12):** Initial formal specification establishing post-task emission reporting.
