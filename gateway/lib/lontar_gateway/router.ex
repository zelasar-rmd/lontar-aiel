defmodule LontarGateway.Router do
  @moduledoc false

  alias LontarGateway.{Config, Confluent, RateLimit}

  def handle(method, path, _headers, body, peer) do
    case {method, path} do
      {"GET", "/healthz"} -> healthz()
      {"POST", "/v1/ingest"} -> ingest(body, peer)
      _ -> {404, %{"error" => "not_found"}, []}
    end
  end

  defp healthz do
    if Config.current().enabled do
      {200, %{"status" => "ok", "service" => "lontar-ingest"}, []}
    else
      {503, %{"status" => "disabled"}, []}
    end
  end

  defp ingest(body, peer) do
    cfg = Config.current()

    cond do
      not cfg.enabled ->
        {503, %{"error" => "gateway_disabled"}, []}

      byte_size(body) > cfg.max_bytes ->
        {413, %{"error" => "payload_too_large", "max_bytes" => cfg.max_bytes}, []}

      true ->
        with {:ok, map} <- decode(body),
             :ok <- validate(map),
             :ok <- rate_limit(peer, map, cfg.rate_per_min) do
          relay(map)
        end
    end
  end

  defp decode(body) do
    try do
      case :json.decode(body) do
        map when is_map(map) -> {:ok, map}
        _ -> {400, %{"error" => "expected_json_object"}, []}
      end
    rescue
      _ -> {400, %{"error" => "invalid_json"}, []}
    end
  end

  defp validate(map) do
    case Map.keys(map) -- LontarGateway.allowed_fields() do
      [] -> :ok
      unknown -> {422, %{"error" => "unknown_fields", "fields" => unknown}, []}
    end
  end

  defp rate_limit(peer, map, limit) do
    keys =
      case map["device_hash"] do
        h when is_binary(h) and h != "" -> ["ip:" <> peer, "dev:" <> h]
        _ -> ["ip:" <> peer]
      end

    case RateLimit.check(keys, limit) do
      :ok -> :ok
      :error -> {429, %{"error" => "rate_limited", "limit_per_min" => limit}, []}
    end
  end

  defp relay(map) do
    if Confluent.configured?() do
      case Confluent.send_event(map) do
        {:ok, _} ->
          {202, %{"status" => "accepted"}, []}

        {:error, {:upstream, status, _}} ->
          {502, %{"error" => "upstream_error", "upstream_status" => status}, []}

        {:error, {:network, _}} ->
          {502, %{"error" => "upstream_unreachable"}, []}
      end
    else
      {503, %{"error" => "gateway_not_configured"}, []}
    end
  end
end
