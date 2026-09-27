defmodule LontarGateway.RateLimit do
  @moduledoc false

  @table :lontar_gateway_ratelimit
  @window_ms 60_000

  def init do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    end

    :ok
  end

  def check(keys, limit) when is_list(keys) do
    Enum.reduce_while(keys, :ok, fn key, :ok ->
      case hit(key, limit) do
        :ok -> {:cont, :ok}
        :error -> {:halt, :error}
      end
    end)
  end

  defp hit(key, limit) do
    bucket = div(System.monotonic_time(:millisecond), @window_ms)
    ets_key = {key, bucket}
    count = :ets.update_counter(@table, ets_key, {2, 1}, {ets_key, 0})

    if count > limit, do: :error, else: :ok
  end
end
