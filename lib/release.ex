defmodule Prometheus.Release do
  def setup do
    Application.load(:prometheus)
    for repository <- Application.fetch_env!(:prometheus, :ecto_repos) do
      repository.__adapter__().storage_up(repository.config())
      {:ok, _, _} = Ecto.Migrator.with_repo(repository, &Ecto.Migrator.run(&1, :up, all: true))
      seeds_script = Application.app_dir(:prometheus, "priv/repository/seeds.exs")
      if File.exists?(seeds_script), do: Code.eval_file(seeds_script)
    end
  end
end
