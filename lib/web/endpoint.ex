defmodule PrometheusEntry.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :prometheus

  @parsers_options [
    parsers: [:urlencoded, :multipart, :json],
    pass: ["application/json"],
    json_decoder: Phoenix.json_library(),
    length: 20_971_520 # ! (20*1024*1024=20971520) bytes - 20 megabytes
  ]

  @cors_options [
    origins: ["http://localhost:5173", ~r/^https?:\/\/.*\.?onrender\.com.*$/, ~r/^https?:\/\/.*\.ngrok(-free)?\.app$/i, ~r/^https?:\/\/.*\.trycloudflare\.com$/],
    allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers: ["authorization", "content-type", "accept"],
    allow_credentials: true,
    max_age: 86_400 # ! (24*60*60=86400) seconds - 1 day
  ]

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers, @parsers_options
  plug Plug.MethodOverride
  plug Plug.Head
  plug Corsica, @cors_options

  plug PrometheusEntry.Router
end
