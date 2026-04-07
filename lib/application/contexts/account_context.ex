defmodule Prometheus.Contexts.AccountContext do
  @moduledoc false
  import Ecto.Query
  alias Prometheus.Contexts.SessionContext
  alias Prometheus.Repository
  alias Prometheus.Schemas.UserSchema
  alias Prometheus.Utils.GenericUtil

  @spec register_user(map()) :: {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, Ecto.Changeset.t()} | {:error, :internal_server_error}
  def register_user(%{"username" => _, "display_name" => _, "email" => _, "password" => _} = attributes) do
    case Repository.insert(UserSchema.create_user_changeset(%UserSchema{}, attributes)) do
      {:ok, %UserSchema{} = user} -> SessionContext.create_session(user.id)
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, :internal_server_error}
    end
  end

  @spec login_user(map()) :: {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :invalid_credentials}
  def login_user(%{"identifier" => user_id, "password" => password}) do
    case get_user_by_identifier(user_id) do
      {:ok, %UserSchema{} = user} ->
        if Argon2.verify_pass(password, user.password_hash),
          do: SessionContext.create_session(user.id),
          else: {:error, :invalid_credentials}
      _ ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @spec get_user_by_identifier(String.t()) :: {:ok, UserSchema.t()} | {:error, :not_found}
  def get_user_by_identifier(user_id) do
    normalized_user_id = GenericUtil.normalize_string(user_id)
     # TODO: Mantenha o uso de cond para futuras atualizações.
    # credo:disable-for-next-line
    repository_query = cond do
      String.contains?(normalized_user_id, "@") -> from(subject in UserSchema, where: subject.email == ^normalized_user_id)
      true -> from(subject in UserSchema, where: subject.username == ^normalized_user_id)
    end
    case Repository.one(repository_query) do
      %UserSchema{} = record -> {:ok, record}
      _ -> {:error, :not_found}
    end
  end
end
