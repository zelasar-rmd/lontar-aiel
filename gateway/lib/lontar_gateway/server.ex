defmodule LontarGateway.Server do
  @moduledoc false
  use GenServer
  require Logger

  alias LontarGateway.{Config, Router}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    cfg = Config.current()
    ip = parse_ip(cfg.bind)

    {:ok, lsock} =
      :gen_tcp.listen(cfg.port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        backlog: 128,
        ip: ip
      ])

    spawn_link(fn -> accept_loop(lsock) end)
    Logger.info("Lontar gateway listening on #{cfg.bind}:#{cfg.port} (enabled=#{cfg.enabled})")
    {:ok, %{lsock: lsock}}
  end

  defp parse_ip(bind) do
    case :inet.parse_address(String.to_charlist(bind)) do
      {:ok, ip} -> ip
      _ -> {127, 0, 0, 1}
    end
  end

  defp accept_loop(lsock) do
    case :gen_tcp.accept(lsock) do
      {:ok, sock} ->
        pid = spawn(fn -> receive do: (:go -> handle(sock)) end)
        :ok = :gen_tcp.controlling_process(sock, pid)
        send(pid, :go)
        accept_loop(lsock)

      {:error, :closed} ->
        :ok

      {:error, _} ->
        accept_loop(lsock)
    end
  end

  defp handle(sock) do
    try do
      peer =
        case :inet.peername(sock) do
          {:ok, {ip, _}} -> ip |> :inet.ntoa() |> to_string()
          _ -> "unknown"
        end

      with {:ok, method, path} <- read_request_line(sock),
           {:ok, headers} <- read_headers(sock, %{}, 64) do
        clen = headers |> Map.get("content-length", "0") |> to_integer()
        max = Config.current().max_bytes

        if clen > max do
          respond(sock, 413, %{"error" => "payload_too_large", "max_bytes" => max})
        else
          {:ok, body} = read_body(sock, clen)
          {status, resp, extra} = Router.handle(method, path, headers, body, peer)
          respond(sock, status, resp, extra)
        end
      else
        _ -> respond(sock, 400, %{"error" => "bad_request"})
      end
    rescue
      _ -> respond(sock, 500, %{"error" => "internal_error"})
    after
      :gen_tcp.close(sock)
    end
  end

  defp read_request_line(sock) do
    :ok = :inet.setopts(sock, packet: :line)

    case :gen_tcp.recv(sock, 0, 5000) do
      {:ok, line} ->
        case String.split(String.trim(line), " ") do
          [method, path | _] -> {:ok, method, path}
          _ -> {:error, :bad_request}
        end

      _ ->
        {:error, :bad_request}
    end
  end

  defp read_headers(_sock, acc, 0), do: {:ok, acc}

  defp read_headers(sock, acc, remaining) do
    case :gen_tcp.recv(sock, 0, 5000) do
      {:ok, line} ->
        trimmed = String.trim(line)

        cond do
          trimmed == "" ->
            {:ok, acc}

          true ->
            case String.split(trimmed, ":", parts: 2) do
              [k, v] ->
                key = String.downcase(String.trim(k))
                read_headers(sock, Map.put(acc, key, String.trim(v)), remaining - 1)

              _ ->
                read_headers(sock, acc, remaining - 1)
            end
        end

      _ ->
        {:ok, acc}
    end
  end

  defp read_body(_sock, 0), do: {:ok, ""}

  defp read_body(sock, len) do
    :ok = :inet.setopts(sock, packet: :raw)

    case :gen_tcp.recv(sock, len, 5000) do
      {:ok, data} -> {:ok, data}
      _ -> {:ok, ""}
    end
  end

  defp respond(sock, status, body, extra \\ []) do
    payload = body |> :json.encode() |> IO.iodata_to_binary()
    reason = reason_phrase(status)
    headers = [{"content-type", "application/json"}, {"connection", "close"} | extra]
    hdr = Enum.map_join(headers, "", fn {k, v} -> "#{k}: #{v}\r\n" end)

    resp =
      "HTTP/1.1 #{status} #{reason}\r\n" <>
        hdr <> "content-length: #{byte_size(payload)}\r\n\r\n" <> payload

    :gen_tcp.send(sock, resp)
  end

  defp to_integer(str) do
    case Integer.parse(str) do
      {n, _} -> n
      _ -> 0
    end
  end

  defp reason_phrase(200), do: "OK"
  defp reason_phrase(202), do: "Accepted"
  defp reason_phrase(400), do: "Bad Request"
  defp reason_phrase(404), do: "Not Found"
  defp reason_phrase(413), do: "Payload Too Large"
  defp reason_phrase(422), do: "Unprocessable Entity"
  defp reason_phrase(429), do: "Too Many Requests"
  defp reason_phrase(500), do: "Internal Server Error"
  defp reason_phrase(502), do: "Bad Gateway"
  defp reason_phrase(503), do: "Service Unavailable"
  defp reason_phrase(_), do: "OK"
end
