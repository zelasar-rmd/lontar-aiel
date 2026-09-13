#!/usr/bin/env elixir

defmodule EmissionCalculator do
  @moduledoc """
  High-performance Elixir script to parse Antigravity session transcripts
  and calculate exact energy consumption, carbon emissions, water footprints,
  and green offset metrics.

  Version: 1.0.0
  Release Date: 2026-09-12
  Engine: BEAM Stream Architecture
  """

  @version "1.0.0"
  @release_date "2026-09-12"

  # Energy & Emission Constants (v1.0.0 Baseline)
  @wh_per_k_token_flash 0.20
  @wh_per_k_token_pro 1.50
  @g_co2_per_wh 0.40
  @ml_water_per_k_token 0.50
  @g_co2_per_tree_day 60.27
  @g_co2_per_tree_minute 0.04185

  def version, do: @version
  def release_date, do: @release_date

  def run(argv) do
    case argv do
      [flag | _] when flag in ["--version", "-v"] ->
        IO.puts("calculate_emission.exs v#{@version} (#{@release_date}) [Elixir #{System.version()}]")

      [flag | _] when flag in ["--help", "-h"] ->
        print_help()

      _ ->
        transcript_path = find_transcript_path(argv)

        case File.exists?(transcript_path) do
          true ->
            process_transcript(transcript_path)
          false ->
            IO.puts(:stderr, "Error: Transcript not found at #{transcript_path}")
            System.halt(1)
        end
    end
  end

  defp print_help do
    IO.puts("""
    calculate_emission.exs v#{@version} (#{@release_date})
    Antigravity Session Environmental Footprint Engine

    Usage:
      elixir calculate_emission.exs [OPTIONS] [TRANSCRIPT_PATH]

    Options:
      -v, --version    Show engine version and exit
      -h, --help       Show this help message and exit

    Arguments:
      TRANSCRIPT_PATH  Optional path to transcript.jsonl.
                       If omitted, automatically locates the most recent active
                       conversation transcript in ~/.gemini/antigravity-cli/brain/.
    """)
  end

  defp find_transcript_path([path | _]) when is_binary(path) and path != "", do: path

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

  defp process_transcript(path) do
    stats =
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.reduce(%{user_chars: 0, model_chars: 0, tool_chars: 0, steps: 0, tool_calls: 0}, &accumulate_step/2)

    total_chars = stats.user_chars + stats.model_chars + stats.tool_chars
    est_tokens = round(total_chars / 3.8) # Average ~3.8 chars per subword token

    # Computations for Flash model baseline
    energy_wh_flash = (est_tokens / 1000.0) * @wh_per_k_token_flash
    carbon_g_flash = energy_wh_flash * @g_co2_per_wh
    water_ml = (est_tokens / 1000.0) * @ml_water_per_k_token

    # Equivalent tree sequestration
    tree_minutes = carbon_g_flash / @g_co2_per_tree_minute

    print_report(path, stats, est_tokens, energy_wh_flash, carbon_g_flash, water_ml, tree_minutes)
  end

  defp accumulate_step(line, acc) do
    chars = String.length(line)
    acc = %{acc | steps: acc.steps + 1}

    cond do
      String.contains?(line, "\"source\":\"USER_EXPLICIT\"") ->
        %{acc | user_chars: acc.user_chars + chars}

      String.contains?(line, "\"source\":\"MODEL\"") ->
        is_tool = String.contains?(line, "\"tool_calls\"")
        tool_inc = if is_tool, do: 1, do: 0
        %{acc | model_chars: acc.model_chars + chars, tool_calls: acc.tool_calls + tool_inc}

      true ->
        %{acc | tool_chars: acc.tool_chars + chars}
    end
  end

  defp print_report(path, stats, tokens, wh, co2_g, water_ml, tree_mins) do
    divider = String.duplicate("─", 72)

    IO.puts("""
    #{divider}
      🌱 ANTIGRAVITY SESSION ENVIRONMENTAL AUDIT (POWERED BY ELIXIR v#{@version})
    #{divider}
      📁 Engine Version    : v#{@version} (#{@release_date})
      📁 Transcript Target : #{Path.basename(Path.dirname(Path.dirname(Path.dirname(path))))}/#{Path.basename(path)}
      🔢 Recorded Steps    : #{stats.steps} turns (#{stats.tool_calls} tool executions)
      📝 Analyzed Volume   : #{tokens |> Integer.to_string() |> format_number()} estimated tokens

    ────────────────────── RESOURCE CONSUMPTION ────────────────────────────
      ⚡ Energy Consumed   : #{:erlang.float_to_binary(wh, decimals: 3)} Wh (#{:erlang.float_to_binary(wh / 1000.0, decimals: 6)} kWh)
      💨 Carbon Footprint  : #{:erlang.float_to_binary(co2_g, decimals: 3)} g CO₂e
      💧 Cooling Water     : #{:erlang.float_to_binary(water_ml, decimals: 2)} mL

    ────────────────────── REAL-WORLD EQUIVALENTS ──────────────────────────
      📱 Smartphone Charge : ~#{:erlang.float_to_binary(wh / 15.0, decimals: 2)} full charges
      🚗 EV Driving        : ~#{:erlang.float_to_binary((wh / 180.0) * 1000.0, decimals: 1)} meters driven
      🌳 Tree Sequestration: Balanced by ~#{:erlang.float_to_binary(tree_mins, decimals: 1)} minutes of tropical tree growth

    ────────────────────── ACTIONABLE GREEN OFFSET ─────────────────────────
      🌿 Mangrove / Peatland : ~#{:erlang.float_to_binary(co2_g / 33.7, decimals: 2)} hours of 1 Indonesian mangrove seedling absorption
      🪸 Coral Reef Buffering: Helps protect ~#{:erlang.float_to_binary(co2_g * 0.05, decimals: 3)} cm² of marine micro-colony
      🔗 Verified Projects   : • LindungiHutan (https://lindungihutan.com)
                               • Coral Guardian (https://coralguardian.org)
                               • Katingan Mentaya Peatland (Borneo)
    #{divider}
    """)
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
