# Lontar AIEL — Ingest Gateway

A **local, dependency-free** Elixir HTTP relay that accepts anonymous emission
receipts from client machines and forwards them to Confluent Cloud. The Confluent
credential lives **only here** (server side); clients never hold it.

- Server: raw OTP `:gen_tcp` (no Hex deps) — HTTP/1.1, JSON via OTP's built-in `:json`.
- Relay: `:httpc` over TLS (peer verified) to the Confluent REST proxy.
- Routes: `GET /healthz`, `POST /v1/ingest`.

## Run

```bash
# config (secret lives here only; mode 600)
install -m 600 /dev/null ~/.gemini/lontar_gateway.env
cat > ~/.gemini/lontar_gateway.env <<'EOF'
CONFLUENT_REST_ENDPOINT=https://pkc-oz2po.ap-southeast-3.aws.confluent.cloud:443/kafka/v3/clusters/lkc-1256pnv
CONFLUENT_TOPIC=ai.inference.raw-events
CONFLUENT_API_KEY=<new>
CONFLUENT_API_SECRET=<new>
INGEST_ENABLED=true
INGEST_MAX_BYTES=8192
INGEST_RATE_PER_MIN=60
EOF
chmod 600 ~/.gemini/lontar_gateway.env

# control the local daemon
gateway/bin/lontar-gateway start
gateway/bin/lontar-gateway status
gateway/bin/lontar-gateway stop
```

The daemon sources `~/.gemini/lontar_gateway.env`, runs `mix run --no-halt`
detached, and writes `~/.gemini/lontar_gateway.pid` + `~/.gemini/lontar_gateway.log`.

## Routes

| Method | Path | Result |
|--------|------|--------|
| GET | `/healthz` | `200 {"status":"ok"}` (or `503` when disabled) |
| POST | `/v1/ingest` | `202` accepted; `400` bad JSON; `413` oversized; `422` unknown fields; `429` rate-limited; `502` upstream error; `503` not configured/disabled |

Enforced: strict field allow-list, 8 KB size cap, per-IP + per-device rate limit
(60/min default). Request bodies are **never logged**.

## Config (env, server-side only)

| Var | Default | Purpose |
|-----|---------|---------|
| `INGEST_BIND` | `127.0.0.1` | bind address (loopback; expose via tunnel/reverse proxy) |
| `INGEST_PORT` | `8787` | listen port |
| `INGEST_ENABLED` | `true` | kill switch |
| `INGEST_MAX_BYTES` | `8192` | payload size cap |
| `INGEST_RATE_PER_MIN` | `60` | per-IP / per-device limit |
| `CONFLUENT_REST_ENDPOINT` | — | Confluent REST base |
| `CONFLUENT_TOPIC` | `ai.inference.raw-events` | target topic |
| `CONFLUENT_API_KEY` / `CONFLUENT_API_SECRET` | — | Confluent Basic auth (secret) |

## Notes

- Binds to `127.0.0.1` by default. To let strangers reach it, expose it with a
  tunnel or reverse proxy you control (see the hardening plan, T1a-R §Exposure).
- Persist across reboots with `crond` `@reboot` or `termux-services`.
