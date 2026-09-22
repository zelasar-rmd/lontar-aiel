#!/usr/bin/env elixir

defmodule EmissionCalculator do
  @moduledoc """
  High-performance Elixir script to parse Antigravity session transcripts
  and calculate exact energy consumption, carbon emissions, water footprints,
  and green offset metrics for both individual turns and cumulative sessions.

  Version: 1.3.0
  Release Date: 2026-09-21
  Engine: BEAM Stream Architecture
  """

  @version "1.3.0"
  @release_date "2026-09-21"

  # Energy & Emission Constants (v1.2.0 Baseline)
  @wh_per_k_token_flash 0.20
  # @wh_per_k_token_pro 1.50 # Reserved for dynamic model tier detection
  @g_co2_per_wh 0.40
  @ml_water_per_k_token 0.50
  @g_co2_per_tree_minute 0.04185

  def version, do: @version
  def release_date, do: @release_date

  def run(argv) do
    {mode, target_path} = parse_args(argv)

    case mode do
      :version ->
        IO.puts("calculate_emission.exs v#{@version} (#{@release_date}) [Elixir #{System.version()}]")

      :help ->
        print_help()

      :ledger ->
        display_ledger()

      _ ->
        transcript_path = find_transcript_path(target_path)

        case File.exists?(transcript_path) do
          true ->
            process_transcript(transcript_path, mode)
          false ->
            IO.puts(:stderr, "Error: Transcript not found at #{transcript_path}")
            System.halt(1)
        end
    end
  end

  defp display_ledger do
    # 1. First try reading lines directly from local git repository origin/telemetry
    lontar_repo = Path.expand("~/lontar-aiel")
    termux_repo = "/data/data/com.termux/files/home/lontar-aiel"
    repo_path = cond do
      File.dir?(Path.join(lontar_repo, ".git")) -> lontar_repo
      File.dir?(Path.join(termux_repo, ".git")) -> termux_repo
      true -> nil
    end

    raw_lines =
      if repo_path do
        System.cmd("git", ["--git-dir=#{Path.join(repo_path, ".git")}", "fetch", "origin", "telemetry", "--quiet"])
        month = Date.utc_today() |> Calendar.strftime("%Y-%m")
        case System.cmd("git", ["--git-dir=#{Path.join(repo_path, ".git")}", "show", "origin/telemetry:logs/#{month}.jsonl"], stderr_to_stdout: true) do
          {output, 0} -> String.split(output, "\n")
          _ -> []
        end
      else
        []
      end

    receipts =
      if raw_lines != [] do
        raw_lines
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&parse_json_fallback/1)
        |> Enum.reject(fn map -> map["session_id"] == nil and map["timestamp"] == nil end)
      else
        # Fallback to local files if cloned
        user_profile = System.get_env("USERPROFILE") || System.get_env("HOME")
        repo_dir = Path.join([user_profile, ".gemini", "antigravity-cli", "brain", "dfa9f5fb-19df-4f6f-bab5-b469e2716691", "scratch", "telemetry-clone"])
        logs_dir = Path.join(repo_dir, "logs") |> String.replace("\\", "/")

        if File.dir?(logs_dir) do
          Path.wildcard("#{logs_dir}/*.jsonl")
          |> Enum.flat_map(fn file ->
            file
            |> File.stream!()
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))
            |> Enum.map(&parse_json_fallback/1)
            |> Enum.reject(fn map -> map["session_id"] == nil and map["timestamp"] == nil end)
          end)
        else
          []
        end
      end
      |> Enum.uniq_by(fn map -> map["session_id"] || map["timestamp"] end)

    if receipts != [] do

      total_sessions = Enum.count(receipts)
      total_tokens = Enum.reduce(receipts, 0, fn r, acc -> acc + (r["total_tokens"] || 0) end)
      total_energy = Enum.reduce(receipts, 0.0, fn r, acc -> acc + (r["energy_wh"] || 0.0) end)
      total_co2 = Enum.reduce(receipts, 0.0, fn r, acc -> acc + (r["co2_grams"] || 0.0) end)
      total_water = Enum.reduce(receipts, 0.0, fn r, acc -> acc + (r["water_ml"] || 0.0) end)
      total_tree = Enum.reduce(receipts, 0.0, fn r, acc -> acc + (r["tree_mins"] || 0.0) end)

      divider = String.duplicate("─", 74)

      # Group by device
      devices_grouped =
        receipts
        |> Enum.group_by(fn r -> r["device"] || "unknown" end)
        |> Enum.map(fn {device, group} ->
          d_tokens = Enum.reduce(group, 0, fn r, a -> a + (r["total_tokens"] || 0) end)
          d_energy = Enum.reduce(group, 0.0, fn r, a -> a + (r["energy_wh"] || 0.0) end)
          d_co2 = Enum.reduce(group, 0.0, fn r, a -> a + (r["co2_grams"] || 0.0) end)
          d_water = Enum.reduce(group, 0.0, fn r, a -> a + (r["water_ml"] || 0.0) end)
          {device, Enum.count(group), d_tokens, d_energy, d_co2, d_water}
        end)

      # Find the most recent timestamp in receipts
      most_recent_ts =
        receipts
        |> Enum.map(& &1["timestamp"])
        |> Enum.reject(&is_nil/1)
        |> Enum.sort()
        |> List.last()

      last_updated_str =
        if most_recent_ts do
          # Format to YYYY-MM-DD HH:00 or clean readable date and hour
          case Regex.run(~r/^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})/, most_recent_ts) do
            [_, date, hour, min] -> "#{date} #{hour}:#{min} UTC (Latest Record: #{date} #{hour}:00)"
            _ -> String.slice(most_recent_ts, 0, 16) <> " UTC"
          end
        else
          "N/A"
        end

      IO.puts("""
      #{divider}
        📜 LONTAR AIEL TELEMETRY LEDGER (GIT BRANCH: telemetry)
        🕒 Latest Audit Entry   : #{last_updated_str}
      #{divider}
        🌐 Total Audited Sessions : #{total_sessions} session(s)
        📝 Cumulative Tokens     : #{total_tokens |> Integer.to_string() |> format_number()} tokens
        ⚡ Total Energy Footprint : #{:erlang.float_to_binary(total_energy, decimals: 3)} Wh (#{:erlang.float_to_binary(total_energy / 1000.0, decimals: 6)} kWh)
        💨 Total Carbon Footprint : #{:erlang.float_to_binary(total_co2, decimals: 3)} g CO₂e
        💧 Total Cooling Water   : #{:erlang.float_to_binary(total_water, decimals: 2)} mL
        🌳 Total Tree Equivalent : ~#{:erlang.float_to_binary(total_tree, decimals: 1)} minutes of tropical tree absorption
      #{divider}
        💻 MACHINE & DEVICE FOOTPRINT BREAKDOWN:
      """)

      Enum.each(devices_grouped, fn {dev, count, tok, wh, co2, _water} ->
        icon = case dev do
          "termux" -> "📱"
          "windows" -> "🪟"
          "macos" -> "🍎"
          "linux" -> "🐧"
          _ -> "💻"
        end
        dev_pad = String.pad_trailing(String.upcase(dev), 10)
        tok_str = tok |> Integer.to_string() |> format_number() |> String.pad_leading(10)
        wh_str = (:erlang.float_to_binary(wh, decimals: 2) <> " Wh") |> String.pad_leading(10)
        co2_str = (:erlang.float_to_binary(co2, decimals: 2) <> " g CO₂e") |> String.pad_leading(12)
        IO.puts("  #{icon} #{dev_pad} : #{count} session(s) | #{tok_str} tok | #{wh_str} | #{co2_str}")
      end)

      IO.puts("""
      #{divider}
        RECENT TELEMETRY RECEIPTS:
      """)

      receipts
      |> Enum.take(-5)
      |> Enum.each(fn r ->
        sid = String.slice(r["session_id"] || "N/A", 0, 8)
        ts = String.slice(r["timestamp"] || "N/A", 0, 19)
        dev = r["device"] || "unknown"
        tokens = r["total_tokens"] || 0
        wh = r["energy_wh"] || 0.0
        co2 = r["co2_grams"] || 0.0
        IO.puts("  • [#{ts}] [#{dev}] Session: #{sid}... | #{tokens} tokens | #{:erlang.float_to_binary(wh, decimals: 2)} Wh | #{:erlang.float_to_binary(co2, decimals: 2)} g CO₂e")
      end)

      IO.puts(divider <> "\n")
    else
      IO.puts(:stderr, "Error: No telemetry logs repository found. Run 'lontar sync' first.")
    end
  end

  defp parse_args(argv) do
    cond do
      Enum.any?(argv, &(&1 in ["--version", "-v"])) ->
        {:version, nil}

      Enum.any?(argv, &(&1 in ["--help", "-h"])) ->
        {:help, nil}

      Enum.any?(argv, &(&1 == "--json")) ->
        path = Enum.find(argv, &(!String.starts_with?(&1, "-")))
        {:json, path}

      Enum.any?(argv, &(&1 in ["--latest", "-l"])) ->
        path = Enum.find(argv, &(!String.starts_with?(&1, "-")))
        {:latest_only, path}

      Enum.any?(argv, &(&1 in ["--ledger", "ledger"])) ->
        {:ledger, nil}

      true ->
        path = List.first(argv)
        {:full, path}
    end
  end

  defp print_help do
    IO.puts("""
    calculate_emission.exs v#{@version} (#{@release_date})
    Antigravity Session Environmental Footprint Engine

    Usage:
      elixir calculate_emission.exs [OPTIONS] [TRANSCRIPT_PATH]

    Options:
      --json           Output machine-readable JSON telemetry receipt
      -l, --latest     Report only the latest turn delta (prompt + reply)
      -v, --version    Show engine version and exit
      -h, --help       Show this help message and exit

    Arguments:
      TRANSCRIPT_PATH  Optional path to transcript.jsonl.
                       If omitted, automatically locates the most recent active
                       conversation transcript in ~/.gemini/antigravity-cli/brain/.
    """)
  end

  defp find_transcript_path(path) when is_binary(path) and path != "", do: path

  defp find_transcript_path(_) do
    base_dir = Path.expand("~/.gemini/antigravity-cli/brain")

    case Path.wildcard("#{base_dir}/*/.system_generated/logs/transcript.jsonl", match_dot: true) do
      [] ->
        IO.puts(:stderr, "No active transcripts found in #{base_dir}")
        System.halt(1)
      files ->
        Enum.max_by(files, fn f ->
          case File.stat(f) do
            {:ok, stat} -> stat.mtime
            _ -> 0
          end
        end)
    end
  end

  defp process_transcript(path, mode) do
    lines =
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.to_list()

    # Calculate overall session stats
    session_stats = Enum.reduce(lines, init_stats(), &accumulate_step/2)

    # Calculate latest turn stats (from last USER_INPUT to EOF)
    last_user_idx =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _idx} -> String.contains?(line, "\"type\":\"USER_INPUT\"") end)
      |> List.last()
      |> case do
        {_, idx} -> idx
        nil -> 0
      end

    turn_lines = Enum.slice(lines, last_user_idx..-1//1)
    turn_stats = Enum.reduce(turn_lines, init_stats(), &accumulate_step/2)

    session_tokens = round((session_stats.user_chars + session_stats.model_chars + session_stats.tool_chars) / 3.8)
    turn_tokens = round((turn_stats.user_chars + turn_stats.model_chars + turn_stats.tool_chars) / 3.8)

    session_wh = (session_tokens / 1000.0) * @wh_per_k_token_flash
    turn_wh = (turn_tokens / 1000.0) * @wh_per_k_token_flash

    session_co2 = session_wh * @g_co2_per_wh
    turn_co2 = turn_wh * @g_co2_per_wh

    session_water_ml = (session_tokens / 1000.0) * @ml_water_per_k_token
    session_tree_mins = session_co2 / @g_co2_per_tree_minute

    print_report(path, mode, turn_stats, turn_tokens, turn_wh, turn_co2, session_stats, session_tokens, session_wh, session_co2, session_water_ml, session_tree_mins)
  end

  defp init_stats do
    %{user_chars: 0, model_chars: 0, tool_chars: 0, steps: 0, tool_calls: 0}
  end

  defp accumulate_step(line, acc) do
    chars = String.length(line)
    acc = %{acc | steps: acc.steps + 1}

    cond do
      String.contains?(line, "\"source\":\"USER_EXPLICIT\"") ->
        %{acc | user_chars: acc.user_chars + chars}

      String.contains?(line, "\"source\":\"MODEL\"") ->
        is_tool = String.contains?(line, "\"tool_calls\"")
        tool_inc = if is_tool do 1 else 0 end
        %{acc | model_chars: acc.model_chars + chars, tool_calls: acc.tool_calls + tool_inc}

      true ->
        %{acc | tool_chars: acc.tool_chars + chars}
    end
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

  def platform_desc do
    prefix = System.get_env("PREFIX") || ""

    case :os.type() do
      {:win32, _} -> "Windows (#{System.get_env("OS") || "win32"})"
      {:unix, :darwin} -> "macOS (Darwin)"
      {:unix, _} ->
        if String.contains?(prefix, "com.termux") do
          "Android / Termux"
        else
          "Linux (#{elem(:os.version(), 0)} #{elem(:os.version(), 1)})"
        end
      _ -> "Unknown Platform"
    end
  end

  defp print_report(path, mode, turn_stats, turn_tokens, turn_wh, turn_co2, session_stats, session_tokens, session_wh, session_co2, water_ml, tree_mins) do
    if mode == :json do
      session_id = Path.basename(Path.dirname(Path.dirname(Path.dirname(path))))
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      energy_str = :erlang.float_to_binary(session_wh, decimals: 3)
      co2_str = :erlang.float_to_binary(session_co2, decimals: 3)
      water_str = :erlang.float_to_binary(water_ml, decimals: 3)
      tree_str = :erlang.float_to_binary(tree_mins, decimals: 3)
      device = detect_device()
      platform = platform_desc()
      
      json = "{\"timestamp\":\"#{now}\",\"session_id\":\"#{session_id}\",\"device\":\"#{device}\",\"platform\":\"#{platform}\",\"model\":\"Gemini Flash / Baseline\",\"turn_count\":#{session_stats.steps},\"total_tokens\":#{session_tokens},\"energy_wh\":#{energy_str},\"co2_grams\":#{co2_str},\"water_ml\":#{water_str},\"tree_mins\":#{tree_str},\"version\":\"#{@version}\"}"
      IO.puts(json)
    else
      divider = String.duplicate("─", 74)

      header = """
      #{divider}
        🌱 ANTIGRAVITY SESSION ENVIRONMENTAL AUDIT (POWERED BY ELIXIR v#{@version})
      #{divider}
        📁 Engine Version    : v#{@version} (#{@release_date})
        📁 Transcript Target : #{Path.basename(Path.dirname(Path.dirname(Path.dirname(path))))}/#{Path.basename(path)}
      """

      turn_block = """
      ──────────────────── ⚡ CURRENT TURN DELTA (LAST INTERACTION) ─────────────────
        📝 Turn Volume       : #{turn_tokens |> Integer.to_string() |> format_number()} tokens (#{turn_stats.steps} step(s))
        ⚡ Turn Energy       : #{:erlang.float_to_binary(turn_wh, decimals: 3)} Wh
        💨 Turn Carbon       : #{:erlang.float_to_binary(turn_co2, decimals: 3)} g CO₂e
      """

      session_block = """
      ──────────────────── 🌐 CUMULATIVE SESSION TOTAL (ALL TURNS) ─────────────────
        🔢 Total Recorded    : #{session_stats.steps} steps (#{session_stats.tool_calls} tool executions)
        📝 Total Volume      : #{session_tokens |> Integer.to_string() |> format_number()} estimated tokens
        ⚡ Total Energy      : #{:erlang.float_to_binary(session_wh, decimals: 3)} Wh (#{:erlang.float_to_binary(session_wh / 1000.0, decimals: 6)} kWh)
        💨 Total Carbon      : #{:erlang.float_to_binary(session_co2, decimals: 3)} g CO₂e
        💧 Total Water       : #{:erlang.float_to_binary(water_ml, decimals: 2)} mL cooling

      ──────────────────── 🌿 REAL-WORLD EQUIVALENTS & OFFSET ──────────────────────
        📱 Smartphone Charge : ~#{:erlang.float_to_binary(session_wh / 15.0, decimals: 2)} full charges
        🚗 EV Driving        : ~#{:erlang.float_to_binary((session_wh / 180.0) * 1000.0, decimals: 1)} meters driven
        🌳 Tree Absorption   : Balanced by ~#{:erlang.float_to_binary(tree_mins, decimals: 1)} minutes of tropical tree growth
        🪸 Conservation Ref  : LindungiHutan (Indonesia) / Coral Guardian
      #{divider}
      """

      case mode do
        :latest_only ->
          IO.puts(header <> turn_block <> divider <> "\n")
        _ ->
          IO.puts(header <> turn_block <> session_block)
      end
    end
  end

  defp format_number(str) do
    str
    |> String.reverse()
    |> String.to_charlist()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp parse_json_fallback(line) do
    session_id = extract_regex(line, ~r/"session_id"\s*:\s*"([^"]+)"/)
    timestamp = extract_regex(line, ~r/"timestamp"\s*:\s*"([^"]+)"/)
    device = extract_regex(line, ~r/"device"\s*:\s*"([^"]+)"/) || "unknown"
    platform = extract_regex(line, ~r/"platform"\s*:\s*"([^"]+)"/) || "N/A"
    total_tokens = extract_number(line, ~r/"total_tokens"\s*:\s*(\d+)/)
    energy_wh = extract_float(line, ~r/"energy_wh"\s*:\s*([\d\.]+)/)
    co2_grams = extract_float(line, ~r/"co2_grams"\s*:\s*([\d\.]+)/)
    water_ml = extract_float(line, ~r/"water_ml"\s*:\s*([\d\.]+)/)
    tree_mins = extract_float(line, ~r/"tree_mins"\s*:\s*([\d\.]+)/)

    %{
      "session_id" => session_id,
      "timestamp" => timestamp,
      "device" => device,
      "platform" => platform,
      "total_tokens" => total_tokens,
      "energy_wh" => energy_wh,
      "co2_grams" => co2_grams,
      "water_ml" => water_ml,
      "tree_mins" => tree_mins
    }
  end

  defp extract_regex(line, regex) do
    case Regex.run(regex, line) do
      [_, val] -> val
      _ -> nil
    end
  end

  defp extract_number(line, regex) do
    case Regex.run(regex, line) do
      [_, val] -> String.to_integer(val)
      _ -> 0
    end
  end

  defp extract_float(line, regex) do
    case Regex.run(regex, line) do
      [_, val] ->
        case Float.parse(val) do
          {f, _} -> f
          _ -> 0.0
        end
      _ -> 0.0
    end
  end
end

EmissionCalculator.run(System.argv())
