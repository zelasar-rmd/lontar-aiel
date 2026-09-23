# 🌿 Lontar AIEL: Real-Time Stream Telemetry & Open Ledger Opt-In Statement

> **Document:** `OPT_IN_STATEMENT.md`  
> **Version:** `1.4.0`  
> **Effective Date:** September 2026  
> **Applicable Pipeline:** Lontar AIEL Confluent Cloud Streaming Engine & Local Audit Ledger  
> **Governing Jurisdiction:** Republic of Indonesia (Personal Data Protection Act - Law No. 27 of 2022)  
> **Primary Data Center & Ingestion Region:** Jakarta (ID-JKT / Asia-Southeast3)  

---

### 1. Purpose & Ecological Mission
1.1. Lontar AI Emission Ledger (**Lontar AIEL**) is an open-source, non-profit ecological accounting and stream governance system.  
1.2. The primary objective is to make the invisible resource consumption of artificial intelligence—specifically energy dissipation ($Wh$), greenhouse gas emissions ($gCO_2e$), and datacenter evaporative cooling water ($mL$)—measurable, transparent, and verifiable in real time.  
1.3. This public alpha release of Lontar AIEL will run for an active evaluation window of **28 days** as part of a public benchmarking and infrastructure stress testing period. Subsequent development phases, expanded features, and production transition timelines will be announced accordingly.  
1.4. By opting into automated telemetry synchronization, you participate in decentralized green computing research and contribute anonymous metrics toward empirical benchmarks across edge developer environments (Android/Termux, Windows, Linux, and macOS).

---

### 2. Telemetry Architecture & Data Destination
2.1. **Edge-to-Cloud Streaming:** Unlike purely passive local loggers, the public edition of Lontar AIEL streams real-time numerical telemetry receipts directly to managed **cloud data streaming clusters** and **stream processing engines**.  
2.2. **Cloud Stream Destination:** Telemetry receipts are streamed directly to managed cloud streaming topics for real-time aggregation and calculation.  
2.3. **Jakarta-Based Processing:** Telemetry ingestion pipelines, proxies, and stream processing gateways are routed to and processed within **Jakarta-based data center infrastructure** (Indonesia).  
2.4. **Dual-Mode Architectural Resilience:** If cloud streaming endpoints are offline, credentials are not configured, or offline mode is chosen, the engine gracefully falls back to local data aggregation without failing or leaking uncommitted data.

---

### 3. Absolute Privacy Guarantee: Zero-Prompt Retention
3.1. Lontar AIEL is engineered under a strict, non-negotiable **Zero-Prompt Retention Guarantee**:
* ❌ **PERMANENTLY PROHIBITED & NEVER CAPTURED:** Raw user prompts, questions, text inputs, model completions, assistant responses, chain-of-thought traces, file system paths, source code, directory structures, repository URLs, API keys, credentials, or personal identifying information (PII).  
3.2. **Local Pre-Ingress Scrubbing:** All transcript inspection happens strictly on the local machine before any network payload is constructed. All conversational and source code text is completely scrubbed.  
3.3. **Permitted Telemetry Schema:** Only aggregate numerical dissipation values and anonymized environment tags are transmitted:
* `event_id`: Unique ephemeral UUID generated for each transmission.
* `timestamp`: ISO-8601 UTC timestamp of the interaction.
* `device_hash`: Irreversible anonymous hash (`SHA256(hostname + local_salt)`).
* `platform`: Operating system tag (`termux`, `windows`, `linux`, `macos`).
* `prompt_tokens` / `completion_tokens` / `total_tokens`: Numerical volume metrics.
* `energy_wh` / `co2_grams` / `water_ml` / `tree_mins`: Derived resource metrics computed from peer-reviewed scientific formulas.
* `engine_version`: Lontar AIEL build and schema release version.

---

### 4. Legal Compliance & Indonesian Data Protection (Law No. 27/2022)
4.1. **Statutory Jurisdiction:** All data transmission, temporary message queuing, and stream processing are subject to and governed by the **Indonesian Personal Data Protection Act (Law No. 27 of 2022)**.  
4.2. **Purpose Limitation:** In strict compliance with the statutory principles of purpose limitation and data minimization under Indonesian law, telemetry data is utilized exclusively for ecological footprint quantification, stream governance demonstration, and public literacy.  
4.3. **Zero PII Storage:** Because data transmitted to the cloud stream is completely anonymized and contains no personal identity, individual profile, or sensitive content, operator privacy remains fully preserved under international and Indonesian statutory benchmarks.

---

### 5. Explicit Opt-In & Revocation Protocol
5.1. **Disabled by Default:** Background telemetry streaming is completely **INACTIVE** upon initial installation. No data is transmitted until the operator explicitly runs:
```bash
lontar opt-in
```
5.2. **Immediate Revocation:** You retain continuous, unconditional control over your machine's telemetry. You can immediately suspend all outbound transmission at any moment by executing:
```bash
lontar daemon stop
```
removing the streaming configuration file (`~/.gemini/lontar_confluent.env`), or by removing Lontar AIEL completely from your system.

---

### 6. Public Ledger & Open Accountability
6.1. Aggregated numerical footprints streamed through the cloud platform may be synthesized into public ecological dashboards, leaderboard summaries, and open Git telemetry records (`telemetry` branch) for collective climate accountability.  
6.2. Operators retain 100% intellectual property, confidentiality, and ownership over all underlying prompts, source files, and software projects developed on their machines.

---

### 7. Operator Consent Declaration
> *"By executing `lontar opt-in`, launching the `lontar daemon`, or providing cloud streaming credentials, you grant explicit consent for sanitized, strictly numerical AI emission receipts to be streamed via Jakarta-based data center infrastructure to designated cloud streaming pipelines under the legal governance of the Indonesian Personal Data Protection Act (Law No. 27 of 2022). You certify that you understand no raw prompts, proprietary source code, or conversational texts are ever transmitted or stored."*
