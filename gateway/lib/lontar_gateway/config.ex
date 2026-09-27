defmodule LontarGateway.Config do
  @moduledoc false

  def load do
    %{
      port: int_env("INGEST_PORT", 8787),
      bind: System.get_env("INGEST_BIND") || "127.0.0.1",
      enabled: bool_env("INGEST_ENABLED", true),
      max_bytes: int_env("INGEST_MAX_BYTES", 8192),
      rate_per_min: int_env("INGEST_RATE_PER_MIN", 60),
      rest_endpoint: System.get_env("CONFLUENT_REST_ENDPOINT") || "",
      topic: System.get_env("CONFLUENT_TOPIC") || "ai.inference.raw-events",
      api_key: System.get_env("CONFLUENT_API_KEY") || "",
      api_secret: System.get_env("CONFLUENT_API_SECRET") || ""
    }
  end

  def current, do: :persistent_term.get({__MODULE__, :config})

  defp int_env(key, default) do
    case System.get_env(key) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {n, _} -> n
          _ -> default
        end
    end
  end

  defp bool_env(key, default) do
    case System.get_env(key) do
      nil -> default
      value -> String.downcase(value) in ["1", "true", "yes", "on"]
    end
  end
end
