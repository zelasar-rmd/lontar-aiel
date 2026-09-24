#!/usr/bin/env elixir

defmodule LontarTelemetryDaemon do
  @moduledoc """
  Real-Time Telemetry Background Daemon for Lontar AIEL.
  
  Monitors Antigravity AI session transcripts in real-time, scrubs all text content
  to ensure zero-prompt retention, computes resource footprint metrics, and streams
  telemetry receipts to Confluent Cloud via REST Proxy / OTLP HTTP.

  Version: 1.4.0-confluent
  Engine: BEAM BEAM Process / Inets Engine
  """

  @version "0.1.0-confluent.2026-09-22-19:00"
  @wh_per_k_token 0.20
  @g_co2_per_wh 0.40
  @ml_water_per_k_token 0.50
  @g_co2_per_tree_minute 0.04185

  def run(argv) do
    :inets.start()
    :ssl.start()

    config = load_config()

    cond do
      "--help" in argv or "-h" in argv ->
        print_help()

      "--test-mode" in argv or "-t" in argv ->
        run_single_pass(config, true)

      "--once" in argv ->
        run_single_pass(config, false)

      true ->
        run_daemon_loop(config)
    end
  end

  def load_config do
    user_home = System.get_env("USERPROFILE") || System.get_env("HOME") || "."
    env_paths = [
      Path.join(user_home, ".gemini/lontar_confluent.env"),
      Path.expand("confluent.env"),
      Path.expand(".env")
    ]

    env_map =
      Enum.reduce(env_paths, %{}, fn path, acc ->
        if File.exists?(path) do
          path
          |> File.stream!()
          |> Enum.reduce(acc, fn line, inner_acc ->
            line = String.trim(line)
            if line != "" and not String.starts_with?(line, "#") and String.contains?(line, "=") do
              [k, v] = String.split(line, "=", parts: 2)
              Map.put(inner_acc, String.trim(k), String.trim(v))
            else
              inner_acc
            end
          end)
        else
          acc
        end
      end)

    %{
      rest_endpoint: System.get_env("CONFLUENT_REST_ENDPOINT") || Map.get(env_map, "CONFLUENT_REST_ENDPOINT", "https://pkc-oz2po.ap-southeast-3.aws.confluent.cloud:443/kafka/v3/clusters/lkc-1256pnv"),
      topic: System.get_env("CONFLUENT_TOPIC") || Map.get(env_map, "CONFLUENT_TOPIC", "ai.inference.raw-events"),
      api_key: System.get_env("CONFLUENT_API_KEY") || Map.get(env_map, "CONFLUENT_API_KEY", "AVUWG44IDTG6WBDK"),
      api_secret: System.get_env("CONFLUENT_API_SECRET") || Map.get(env_map, "CONFLUENT_API_SECRET", "cfltSr31+CknXpiI1jpb1gpDsMOErnPB02Ukv+9yjEpeUh7ouHypDWS/oN3maqxg"),
      enabled: System.get_env("LONTAR_TELEMETRY_ENABLED") || Map.get(env_map, "LONTAR_TELEMETRY_ENABLED", "true"),
      device: detect_device()
    }
  end

  def detect_device do
    prefix = System.get_env("PREFIX") || ""
    termux_ver = System.get_env("TERMUX_VERSION")

    cond do
      System.get_env("LONTAR_DEVICE") != nil ->
        System.get_env("LONTAR_DEVICE") |> String.downcase()

      String.contains?(prefix, "com.termux") or termux_ver != nil ->
        "termux"

      match?({:win32, _}, :os.type()) or System.get_env("OS") == "Windows_NT" ->
        "windows"

      match?({:unix, :darwin}, :os.type()) ->
        "macos"

      true ->
        "linux"
    end
  end

  def generate_device_hash do
    hostname = System.cmd("hostname", []) |> elem(0) |> String.trim()
    :crypto.hash(:sha256, "#{hostname}_lontar_salt_2026") |> Base.encode16(case: :lower)
  end

  def find_latest_transcript do
    base_dirs = [
      Path.expand("~/.gemini/antigravity-cli/brain"),
      Path.expand("~/.gemini/antigravity/brain")
    ]

    files = Enum.flat_map(base_dirs, fn dir ->
      Path.wildcard("#{dir}/*/.system_generated/logs/transcript.jsonl", match_dot: true)
    end)

    case files do
      [] -> nil
      _ ->
        Enum.max_by(files, fn f ->
          case File.stat(f) do
            {:ok, stat} -> stat.mtime
            _ -> 0
          end
        end)
    end
  end

  def process_transcript_file(path) do
    if File.exists?(path) do
      session_id = Path.basename(Path.dirname(Path.dirname(Path.dirname(path))))

      lines =
        path
        |> File.stream!()
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Enum.to_list()

      stats = Enum.reduce(lines, %{user_chars: 0, model_chars: 0, tool_chars: 0, steps: 0}, fn line, acc ->
        chars = String.length(line)
        cond do
          String.contains?(line, "\"source\":\"USER_EXPLICIT\"") -> %{acc | user_chars: acc.user_chars + chars, steps: acc.steps + 1}
          String.contains?(line, "\"source\":\"MODEL\"") -> %{acc | model_chars: acc.model_chars + chars, steps: acc.steps + 1}
          true -> %{acc | tool_chars: acc.tool_chars + chars, steps: acc.steps + 1}
        end
      end)

      total_tokens = round((stats.user_chars + stats.model_chars + stats.tool_chars) / 3.8)
      prompt_tokens = round(stats.user_chars / 3.8)
      completion_tokens = round((stats.model_chars + stats.tool_chars) / 3.8)

      energy_wh = (total_tokens / 1000.0) * @wh_per_k_token
      co2_grams = energy_wh * @g_co2_per_wh
      water_ml = (total_tokens / 1000.0) * @ml_water_per_k_token
      land_cm2 = energy_wh * 1.25
      tree_mins = co2_grams / @g_co2_per_tree_minute

      now = DateTime.utc_now() |> DateTime.to_iso8601()
      device = detect_device()
      device_hash = generate_device_hash()

      %{
        "event_id" => generate_uuid_v4(),
        "timestamp" => now,
        "session_id" => session_id,
        "device" => device,
        "device_hash" => String.slice(device_hash, 0, 16),
        "engine_version" => @version,
        "model_tier" => "flash",
        "turn_count" => stats.steps,
        "prompt_tokens" => prompt_tokens,
        "completion_tokens" => completion_tokens,
        "total_tokens" => total_tokens,
        "energy_wh" => Float.round(energy_wh, 4),
        "co2_grams" => Float.round(co2_grams, 4),
        "water_ml" => Float.round(water_ml, 4),
        "land_cm2" => Float.round(land_cm2, 4),
        "tree_mins" => Float.round(tree_mins, 4)
      }
    else
      nil
    end
  end

  def run_single_pass(config, dry_run) do
    path = find_latest_transcript()

    if path do
      payload = process_transcript_file(path)

      if payload do
        json_payload = encode_json(payload)

        IO.puts("""
        📜 LONTAR TELEMETRY REAL-TIME DAEMON (v#{@version})
        ========================================================================
        🔒 Privacy Check  : ZERO PROMPT RETENTION GUARANTEED (Text Scrubbed)
        💻 Target Device   : #{payload["device"]} (#{payload["device_hash"]})
        📝 Total Volume    : #{payload["total_tokens"]} tokens
        ⚡ Computed Energy  : #{payload["energy_wh"]} Wh | 💨 #{payload["co2_grams"]} g CO₂e
        ========================================================================
        """)

        if dry_run or config.rest_endpoint == "" or config.api_key == "" do
          IO.puts("🔍 Dry-Run Mode / Unconfigured Confluent Credentials.")
          IO.puts("📦 Transmitted Payload Payload Preview:\n#{json_payload}\n")
        else
          send_to_confluent(config, json_payload)
        end
      else
        IO.puts(:stderr, "Error: Unable to process transcript file.")
      end
    else
      IO.puts("No active session transcripts found.")
    end
  end

  def run_daemon_loop(config) do
    IO.puts("🚀 Starting Lontar AIEL Real-Time Telemetry Daemon (Press Ctrl+C to stop)...")
    loop(config, nil, 0)
  end

  defp loop(config, last_mtime, count) do
    path = find_latest_transcript()

    current_mtime =
      if path do
        case File.stat(path) do
          {:ok, stat} -> stat.mtime
          _ -> nil
        end
      else
        nil
      end

    if current_mtime != nil and current_mtime != last_mtime do
      payload = process_transcript_file(path)

      if payload do
        json_payload = encode_json(payload)
        IO.puts("[#{DateTime.utc_now() |> DateTime.to_iso8601()}] ⚡ Real-Time Stream Event ##{count + 1} | Tokens: #{payload["total_tokens"]} | Energy: #{payload["energy_wh"]} Wh")

        if config.rest_endpoint != "" and config.api_key != "" do
          send_to_confluent(config, json_payload)
        end
      end
    end

    # Sleep 3 seconds before next telemetry check
    Process.sleep(3000)
    loop(config, current_mtime || last_mtime, count + 1)
  end

  def send_to_confluent(config, json_payload) do
    # Convert to Confluent Cloud API v3 format if URL doesn't contain it
    base_url = String.trim_trailing(config.rest_endpoint, "/")
    url =
      if String.contains?(base_url, "/kafka/v3/clusters") do
        "#{base_url}/topics/#{config.topic}/records"
      else
        "#{base_url}/topics/#{config.topic}"
      end

    auth_header = "Basic " <> Base.encode64("#{config.api_key}:#{config.api_secret}")

    headers = [
      {~c"content-type", ~c"application/json"},
      {~c"authorization", String.to_charlist(auth_header)}
    ]

    post_body =
      if String.contains?(base_url, "/kafka/v3/clusters") do
        ~s({"value": {"type": "JSON", "data": #{json_payload}}})
      else
        ~s({"records": [{"value": #{json_payload}}]})
      end

    case :httpc.request(:post, {String.to_charlist(url), headers, ~c"application/json", String.to_charlist(post_body)}, [], []) do
      {:ok, {{_, 200, _}, _, response_body}} ->
        IO.puts("✅ Successfully streamed receipt to Confluent Topic '#{config.topic}'")
        IO.puts("   Response: #{to_string(response_body)}")

      {:ok, {{_, status, _}, _, response_body}} ->
        IO.puts(:stderr, "⚠️ Confluent REST Proxy returned status #{status}: #{to_string(response_body)}")

      {:error, reason} ->
        IO.puts(:stderr, "❌ Network error transmitting to Confluent: #{inspect(reason)}")
    end
  end

  def print_help do
    IO.puts("""
    lontar_telemetry_daemon.exs v#{@version}
    Lontar AIEL Background Real-Time Confluent Telemetry Daemon

    Usage:
      elixir scripts/lontar_telemetry_daemon.exs [OPTIONS]

    Options:
      -t, --test-mode   Run single pass and display scrubbed JSON payload without posting
      --once            Run single pass and attempt post to Confluent REST Proxy
      -h, --help        Show this help message and exit

    Daemon Mode (Default):
      Runs continuously in the background monitoring active transcripts every 3 seconds.
    """)
  end

  defp generate_uuid_v4 do
    bin = :crypto.strong_rand_bytes(16)
    <<u0::32, u1::16, _::4, u2::12, _::2, u3::14, u4::48>> = bin
    <<u0::32, u1::16, 4::4, u2::12, 2::2, u3::14, u4::48>>
    |> Base.encode16(case: :lower)
    |> format_uuid()
  end

  defp format_uuid(<<a::binary-8, b::binary-4, c::binary-4, d::binary-4, e::binary-12>>) do
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end

  defp encode_json(map) when is_map(map) do
    entries =
      Enum.map(map, fn {k, v} ->
        val_str = case v do
          str when is_binary(str) -> "\"#{str}\""
          num when is_number(num) -> "#{num}"
          bool when is_boolean(bool) -> "#{bool}"
          sub_map when is_map(sub_map) -> encode_json(sub_map)
          sub_list when is_list(sub_list) -> "[" <> Enum.map_join(sub_list, ",", &encode_json/1) <> "]"
          _ -> "null"
        end
        "\"#{k}\":#{val_str}"
      end)
    "{" <> Enum.join(entries, ",") <> "}"
  end

  defp decode_json_simple(json_str) do
    # Lightweight fallback helper
    json_str
    |> String.trim()
  end
end

LontarTelemetryDaemon.run(System.argv())
