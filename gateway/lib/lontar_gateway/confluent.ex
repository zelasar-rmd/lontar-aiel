defmodule LontarGateway.Confluent do
  @moduledoc false

  def configured? do
    c = LontarGateway.Config.current()
    c.rest_endpoint != "" and c.api_key != "" and c.api_secret != ""
  end

  def send_event(map) do
    c = LontarGateway.Config.current()
    url = "#{String.trim_trailing(c.rest_endpoint, "/")}/topics/#{c.topic}/records"

    payload =
      %{"value" => %{"type" => "JSON", "data" => map}}
      |> :json.encode()
      |> IO.iodata_to_binary()

    auth = "Basic " <> Base.encode64(c.api_key <> ":" <> c.api_secret)

    headers = [
      {~c"content-type", ~c"application/json"},
      {~c"authorization", String.to_charlist(auth)}
    ]

    http_opts = [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 3,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ],
      timeout: 10_000,
      connect_timeout: 5_000
    ]

    case :httpc.request(
           :post,
           {String.to_charlist(url), headers, ~c"application/json", String.to_charlist(payload)},
           http_opts,
           []
         ) do
      {:ok, {{_, status, _}, _, _}} when status in [200, 201, 202] ->
        {:ok, status}

      {:ok, {{_, status, _}, _, body}} ->
        {:error, {:upstream, status, to_string(body)}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end
end
