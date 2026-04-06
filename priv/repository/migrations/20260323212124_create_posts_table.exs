defmodule Prometheus.Repository.Migrations.CreatePostsTable do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :string, primary_key: true

      add :title, :string, size: 255, null: false
      add :content, :string, size: 2_000, null: false
      add :author_id, references(:users, type: :string, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end
    create index(:posts, [:title])
    create index(:posts, [:author_id])
  end
end
