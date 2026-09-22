# 🛡️ Lontar AIEL: Privacy Protocol, Data Security Standards & Terms of Service

> **Document Version:** `v1.0.0-alpha`  
> **Effective Date:** September 22, 2026  
> **Scope:** Lontar AI Emission Ledger (Lontar AIEL) Background Telemetry Daemon & Confluent Data Stream Pipeline  

---

## 1. Executive Privacy Mandate: Zero-Prompt Retention

Lontar AIEL is built on a non-negotiable architectural guarantee:

> **WE NEVER CAPTURE, STORE, OR TRANSMIT YOUR CONVERSATIONS, PROMPTS, CODE, OR AGENT OUTPUTS.**

The background telemetry collector is hardcoded to sanitize every event locally on your edge device **BEFORE** any network packet leaves your machine.

---

## 2. Permitted Telemetry Payload Specification

When background streaming is enabled, the daemon transmits strictly anonymous numerical resource metrics to the Confluent Cloud telemetry topic. 

### 2.1 Complete Transmitted Schema
```json
{
  "event_id": "8f3b2a19-4c01-4b8a-921d-55e123456789",
  "timestamp": "2026-09-22T18:30:00Z",
  "device_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "platform": "windows",
  "engine_version": "v1.3.0-confluent",
  "model_tier": "flash",
  "prompt_tokens": 1250,
  "completion_tokens": 420,
  "total_tokens": 1670,
  "energy_wh": 0.334,
  "co2_grams": 0.1336,
  "water_ml": 0.835,
  "tree_mins": 3.19
}
```

### 2.2 Expressly Prohibited Data Categories
The following data points are **PERMANENTLY EXCLUDED** from collection:
* ❌ Raw user prompts, questions, or text inputs.
* ❌ Model responses, assistant replies, or reasoning traces.
* ❌ File paths, source code snippets, directory names, or repository URLs.
* ❌ API keys, tokens, environment variables, or secrets.
* ❌ User identity, IP addresses, email addresses, or usernames.

---

## 3. Data Security & Encryption Standards

1. **In-Transit Encryption:** All telemetry streams transmitted to Confluent Cloud use **TLS 1.3** transport-layer encryption over HTTPS / SASL_SSL.
2. **Anonymous Device Hashing:** Device identifiers are hashed locally using `SHA-256(hostname + local_salt)` to prevent cross-device tracking while allowing multi-device emissions breakdown.
3. **Local Storage Isolation:** Local session transcripts remain strictly within your device's application data directory (`~/.gemini/antigravity-cli/brain/`).

---

## 4. User Consent & Opt-In Protocol

1. **Default State:** Telemetry collection is **DISABLED** until the user explicitly runs `lontar opt-in`.
2. **Revocation:** Users may immediately suspend all background telemetry collection at any time by executing:
   ```bash
   lontar daemon stop
   ```
   or removing their Confluent credentials from `~/.gemini/lontar_confluent.env`.

---

## 5. Terms of Service Summary

By opting into the Lontar AIEL Confluent Telemetry Stream:
* You grant permission for the local Elixir daemon to inspect session transcript line byte sizes for the sole purpose of computing energy, carbon, and water metrics.
* You acknowledge that aggregated anonymous carbon metrics may be published to the public Lontar AIEL leaderboard / ledger for environmental transparency.
* You retain 100% ownership of your code, prompts, and local session content.
