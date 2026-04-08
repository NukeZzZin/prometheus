ExUnit.start(max_cases: :erlang.system_info(:schedulers_online) * 2)
Ecto.Adapters.SQL.Sandbox.mode(Prometheus.Repository, :manual)
