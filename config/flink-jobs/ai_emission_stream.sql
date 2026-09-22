-- ==============================================================================
-- 📜 Lontar AIEL: Apache Flink Stream Processing SQL Job
-- ==============================================================================
-- Version: v0.1.0-confluent.2026-09-22-19:00
-- Scope: Real-Time Stream-Table Joins & Session Window Aggregations for Confluent Cloud

-- 1. Create Raw Telemetry Source Table (Kafka Topic: ai.inference.raw-events)
CREATE TABLE raw_ai_inference_events (
    event_id STRING,
    `timestamp` STRING,
    session_id STRING,
    device_hash STRING,
    device_platform STRING,
    engine_version STRING,
    model_tier STRING,
    datacenter_region STRING,
    ttft_sec DOUBLE,
    tps_rate DOUBLE,
    prompt_tokens BIGINT,
    completion_tokens BIGINT,
    total_tokens BIGINT,
    energy_wh DOUBLE,
    co2_grams DOUBLE,
    water_ml DOUBLE,
    land_cm2 DOUBLE,
    tree_mins DOUBLE,
    event_time AS CAST(TO_TIMESTAMP(`timestamp`) AS TIMESTAMP_LTZ(3)),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'ai.inference.raw-events',
    'properties.bootstrap.servers' = '${CONFLUENT_BOOTSTRAP_SERVER}',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONFLUENT_API_KEY}" password="${CONFLUENT_API_SECRET}";',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset'
);

-- 2. Create Model Hardware Specs Reference Table
CREATE TABLE model_hardware_specs (
    model_tier STRING PRIMARY KEY NOT ENFORCED,
    p_gpu_kw DOUBLE,
    p_nongpu_kw DOUBLE,
    u_gpu DOUBLE,
    u_nongpu DOUBLE,
    baseline_tps DOUBLE,
    record_time TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
    WATERMARK FOR record_time AS record_time - INTERVAL '1' MINUTE
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'reference.model.hardware-specs',
    'properties.bootstrap.servers' = '${CONFLUENT_BOOTSTRAP_SERVER}',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONFLUENT_API_KEY}" password="${CONFLUENT_API_SECRET}";',
    'key.format' = 'raw',
    'value.format' = 'json'
);

-- 3. Create Regional Grid Multipliers Reference Table
CREATE TABLE grid_regional_metrics (
    region STRING PRIMARY KEY NOT ENFORCED,
    pue DOUBLE,
    cif_kg_co2_per_kwh DOUBLE,
    wue_site_l_per_kwh DOUBLE,
    wue_source_l_per_kwh DOUBLE,
    lif_cm2_per_kwh DOUBLE,
    record_time TIMESTAMP_LTZ(3) METADATA FROM 'timestamp',
    WATERMARK FOR record_time AS record_time - INTERVAL '1' MINUTE
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'reference.grid.regional-metrics',
    'properties.bootstrap.servers' = '${CONFLUENT_BOOTSTRAP_SERVER}',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONFLUENT_API_KEY}" password="${CONFLUENT_API_SECRET}";',
    'key.format' = 'raw',
    'value.format' = 'json'
);

-- 4. Create Enriched Real-Time Receipts Sink Table (Kafka Topic: ai.emission.enriched-receipts)
CREATE TABLE enriched_ai_emission_receipts (
    event_id STRING,
    session_id STRING,
    device_hash STRING,
    device_platform STRING,
    model_tier STRING,
    datacenter_region STRING,
    total_tokens BIGINT,
    energy_wh DOUBLE,
    co2_grams DOUBLE,
    water_ml DOUBLE,
    land_cm2 DOUBLE,
    tree_mins DOUBLE,
    processed_at TIMESTAMP(3)
) WITH (
    'connector' = 'kafka',
    'topic' = 'ai.emission.enriched-receipts',
    'properties.bootstrap.servers' = '${CONFLUENT_BOOTSTRAP_SERVER}',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONFLUENT_API_KEY}" password="${CONFLUENT_API_SECRET}";',
    'format' = 'json'
);

-- 5. Flink Streaming Query: Dynamic Stream-Table Join
INSERT INTO enriched_ai_emission_receipts
SELECT
    e.event_id,
    e.session_id,
    e.device_hash,
    e.device_platform,
    e.model_tier,
    e.datacenter_region,
    e.total_tokens,
    -- Energy in Wh
    (((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu) * g.pue) * 1000.0 AS energy_wh,
    -- Carbon in g CO2e
    ((((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu) * g.pue)) * g.cif_kg_co2_per_kwh * 1000.0 AS co2_grams,
    -- Water in mL
    (((((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu)) * g.wue_site_l_per_kwh) +
     ((((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu) * g.pue) * g.wue_source_l_per_kwh)) * 1000.0 AS water_ml,
    -- Land in cm2
    ((((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu) * g.pue)) * g.lif_cm2_per_kwh AS land_cm2,
    -- Tree mins
    (((((e.ttft_sec + (e.completion_tokens / COALESCE(NULLIF(e.tps_rate, 0.0), h.baseline_tps))) / 3600.0) *
        (h.p_gpu_kw * h.u_gpu + h.p_nongpu_kw * h.u_nongpu) * g.pue)) * g.cif_kg_co2_per_kwh * 1000.0) / 0.04185 AS tree_mins,
    CURRENT_TIMESTAMP AS processed_at
FROM raw_ai_inference_events e
JOIN model_hardware_specs FOR SYSTEM_TIME AS OF e.event_time AS h
    ON e.model_tier = h.model_tier
JOIN grid_regional_metrics FOR SYSTEM_TIME AS OF e.event_time AS g
    ON e.datacenter_region = g.region;
