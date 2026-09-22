# 📜 Lontar AIEL: Scientific Calculation & Footprint Specification (v2.0.0-confluent)

> **Document Version:** `2.0.0-confluent`  
> **Status:** Production Standard (Confluent Cloud Stream Platform)  
> **Scope:** Scientific AI Model Inference Energy Accounting, Infrastructure-Aware Resource Dissipation, and Real-Time Confluent Stream Processing  

---

## 1. Executive Overview & Scope

Lontar AIEL computes a **3-Pillar Environmental Footprint** for artificial intelligence inference:
1. **Carbon Footprint ($CO_2e$):** Atmospheric greenhouse gas emissions driven by regional grid carbon intensity.
2. **Water Footprint (Liters):** Combined **on-site** datacenter evaporative cooling ($WUE_{site}$) and **off-site** water consumed in thermal electricity generation ($WUE_{source}$).
3. **Land Footprint ($cm^2$):** Direct and indirect land transformation ($LIF$) required for energy generation infrastructure (hydropower reservoirs, bioenergy, solar/wind farms, coal mining).

The calculation engine operates as an **infrastructure-aware, real-time stream processor** on Confluent Cloud & Apache Flink.

---

## 2. Infrastructure-Aware Inference Energy Modeling

Inference energy accounts for 80–90% of an AI model's operational lifecycle footprint. Rather than relying solely on coarse parameter heuristics, Lontar AIEL models hardware execution time, GPU/non-GPU power draw, and datacenter Power Usage Effectiveness ($PUE$).

### 2.1 Total Inference Execution Time ($T_i$)
$$\text{Total Time } T_i \text{ (hours)} = \frac{L_i + \frac{\text{Output Tokens}}{R_i}}{3600}$$
* **$L_i$:** Time-to-First-Token (TTFT) latency (seconds).
* **$R_i$:** Generation throughput rate in tokens per second (TPS).

### 2.2 Infrastructure Energy per Query ($E_{query}$)
$$E_{query} \text{ (kWh)} = T_i \times \left( P_{\text{GPU}} \times U_{\text{GPU}} + P_{\text{non-GPU}} \times U_{\text{non-GPU}} \right) \times PUE$$
* **$P_{\text{GPU}}$ / $P_{\text{non-GPU}}$:** Rated peak power draw of GPU accelerators (e.g., NVIDIA H100 = 0.70 kW, A100 = 0.40 kW) and host system (CPUs, RAM, NVMe storage) in kW.
* **$U_{\text{GPU}}$ / $U_{\text{non-GPU}}$:** Hardware utilization fraction during inference (typically 0.50–0.85).
* **$PUE$:** Power Usage Effectiveness multiplier (e.g., 1.10 for hyper-efficient Google/AWS datacenters, 1.40 for average facilities).

---

## 3. The Three Footprint Formulations

Once $E_{query}$ is computed, environmental impact is evaluated dynamically using regional grid metrics:

### 3.1 Carbon Footprint ($CO_2e$)
$$\text{Carbon } (kgCO_2e) = E_{query} \times CIF$$
* **$CIF$ (Carbon Intensity Factor):** Measured in $kgCO_2e / kWh$. Varies by regional electricity grid (e.g., $0.04\text{ kg } CO_2/kWh$ in nuclear-heavy France, $0.40\text{ kg } CO_2/kWh$ global cloud average, $0.70\text{ kg } CO_2/kWh$ in coal-heavy grids).

### 3.2 Dual-Scope Water Footprint ($W_{\text{total}}$)
$$\text{Water } (\text{Liters}) = \left( \frac{E_{query}}{PUE} \times WUE_{\text{site}} \right) + \left( E_{query} \times WUE_{\text{source}} \right)$$
* **$WUE_{\text{site}}$ (On-Site Evaporative Cooling):** Direct water evaporated in datacenter cooling towers (Liters / kWh of IT compute).
* **$WUE_{\text{source}}$ (Off-Site Power Generation Water):** Water consumed upstream in thermal power plant cooling towers, hydroelectric reservoir evaporation, and fuel extraction.

### 3.3 Land Footprint ($L_{\text{total}}$)
$$\text{Land } (cm^2) = E_{query} \times LIF$$
* **$LIF$ (Land Intensity Factor):** Measured in $cm^2 / kWh$. Accounts for land area transformed by solar arrays, wind turbine footprints, coal mining, or hydroelectric reservoirs.

---

## 4. Real-Time Confluent Stream Processing & Flink Pipeline

```text
┌──────────────────────────┐      ┌──────────────────────────┐      ┌──────────────────────────┐
│ Anonymized Local Event   │ ───► │ Confluent Topic:         │ ───► │ Apache Flink Stream      │
│ (Tokens, TTFT, TPS)      │      │ raw.ai.inference.events  │      │ Temporal Table Join      │
└──────────────────────────┘      └──────────────────────────┘      └────────────┬─────────────┘
                                                                                 │
                                  ┌──────────────────────────┐                   │
                                  │ Reference Streams:       │ ──────────────────┘
                                  │ • model.hardware.specs   │
                                  │ • grid.regional.metrics  │
                                  └──────────────────────────┘
                                               │
                                               ▼
                                  ┌──────────────────────────┐
                                  │ Enriched Stream:         │
                                  │ Carbon, Water, Land      │
                                  └──────────────────────────┘
```

### 4.1 Temporal Stream-Table Joins in Flink
Flink SQL enriches incoming raw telemetry events in real time:
```sql
SELECT
  e.event_id,
  e.session_id,
  e.device_hash,
  -- Compute Total Energy (kWh)
  ((e.ttft_sec + (e.output_tokens / m.tps_rate)) / 3600.0) * 
    (m.p_gpu_kw * m.u_gpu + m.p_nongpu_kw * m.u_nongpu) * g.pue AS energy_kwh,
  -- Compute 3 Footprints
  energy_kwh * g.cif_kg_co2_per_kwh AS carbon_co2_kg,
  ((energy_kwh / g.pue) * g.wue_site) + (energy_kwh * g.wue_source) AS water_liters,
  energy_kwh * g.lif_cm2_per_kwh AS land_cm2
FROM ai_inference_raw_events e
JOIN model_hardware_specs FOR SYSTEM_TIME AS OF e.event_time AS m
  ON e.model_tier = m.model_tier
JOIN grid_regional_metrics FOR SYSTEM_TIME AS OF e.event_time AS g
  ON e.datacenter_region = g.region;
```

---

## 5. Actionable Ecological Sequestration Equivalents

To make micro-emissions intuitive for human decision-making:
1. **Mature Tropical Rainforest Tree:** Absorbs ~`22 kg CO₂ / year` (~`0.04185 g CO₂ / minute`).
   $$\text{Tree Absorption Minutes} = \frac{\text{Carbon Emitted (g)}}{0.04185}$$
2. **Mangrove Seedling (Blue Carbon - LindungiHutan):** Sequester ~`12.3 kg CO₂ / year` with 4x higher sediment carbon retention than terrestrial forests.
3. **Cooling Water Comparison:** $1\text{ Liter}$ of datacenter water = ~2 standard drinking water bottles ($500\text{ mL}$).

---

## 6. Dual-Scope Accounting: Turn Delta vs. Cumulative Session State

1. **Turn Delta (Incremental Prompt/Response):**
   * Computes marginal resource cost from single prompt + response execution.
2. **Session Total (Cumulative Thread History):**
   * Flink `SESSION WINDOW` aggregates cumulative token inflation, KV-cache retention, and total resource consumption across multi-turn interactions.
