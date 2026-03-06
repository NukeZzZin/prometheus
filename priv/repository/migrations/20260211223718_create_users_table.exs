defmodule Prometheus.Repository.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :bigint, primary_key: true

      add :username, :string, null: false
      add :display_name, :string, null: false
      add :email, :string, size: 320, null: false

      add :user_flags, :bigint, default: 0b0, null: false

      add :password_hash, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:users, ["lower(username)"])
    create unique_index(:users, ["lower(email)"])
  end
end
