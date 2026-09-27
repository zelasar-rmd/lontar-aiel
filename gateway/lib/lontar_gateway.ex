defmodule LontarGateway do
  @moduledoc """
  Lontar AIEL Ingest Gateway — a local, dependency-free HTTP relay that accepts
  anonymous emission receipts from client machines and relays them to Confluent
  Cloud. The Confluent credential lives only here (server side); clients never
  hold it.
  """

  @allowed_fields ~w(
    event_id timestamp session_id device_hash device_platform engine_version
    model_tier datacenter_region ttft_sec tps_rate prompt_tokens completion_tokens
    total_tokens energy_wh co2_grams water_ml land_cm2 tree_mins
  )

  def allowed_fields, do: @allowed_fields
end
