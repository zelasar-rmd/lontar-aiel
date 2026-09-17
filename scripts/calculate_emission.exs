#!/usr/bin/env elixir

defmodule EmissionCalculator do
  @moduledoc """
  High-performance Elixir script to parse Antigravity session transcripts
  and calculate exact energy consumption, carbon emissions, water footprints,
  and green offset metrics for both individual turns and cumulative sessions.

  Version: 1.2.0
  Release Date: 2026-09-13
  Engine: BEAM Stream Architecture
  """

  @version "1.2.0"
  @release_date "2026-09-13"

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

    case Path.wildcard("#{base_dir}/*/.system_generated/logs/transcript.jsonl") do
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

  defp print_report(path, mode, turn_stats, turn_tokens, turn_wh, turn_co2, session_stats, session_tokens, session_wh, session_co2, water_ml, tree_mins) do
    if mode == :json do
      session_id = Path.basename(Path.dirname(Path.dirname(Path.dirname(path))))
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      energy_str = :erlang.float_to_binary(session_wh, decimals: 3)
      co2_str = :erlang.float_to_binary(session_co2, decimals: 3)
      water_str = :erlang.float_to_binary(water_ml, decimals: 3)
      tree_str = :erlang.float_to_binary(tree_mins, decimals: 3)
      
      json = "{\"timestamp\":\"#{now}\",\"session_id\":\"#{session_id}\",\"model\":\"Gemini Flash / Baseline\",\"turn_count\":#{session_stats.steps},\"total_tokens\":#{session_tokens},\"energy_wh\":#{energy_str},\"co2_grams\":#{co2_str},\"water_ml\":#{water_str},\"tree_mins\":#{tree_str},\"version\":\"#{@version}\"}"
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
end

EmissionCalculator.run(System.argv())
