defmodule Prometheus.Contexts.AccountContext do
  import Ecto.Query

  alias Prometheus.Contexts.SessionContext
  alias Prometheus.Repository
  alias Prometheus.Utils.TokenUtil
  alias Prometheus.Schemas.UserSchema

  @spec register_user(map()) ::
    {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, Ecto.Changeset.t()}
  def register_user(attributes) when is_map(attributes) do
    with {:ok, %UserSchema{} = user} <- Repository.insert(UserSchema.create_user_changeset(%UserSchema{}, attributes)),
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} <- SessionContext.create_session(user.id) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  @spec login_user(pos_integer() | binary(), binary()) ::
    {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :invalid_credentials}
  def login_user(identifier, password) when is_binary(password) do
    with {:ok, %UserSchema{} = user} <- get_user_by_identifier(identifier),
      true <- Argon2.verify_pass(password, user.password_hash),
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} <- SessionContext.create_session(user.id) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
      else
        false ->
          Argon2.no_user_verify()
          {:error, :invalid_credentials}
        _ ->
          {:error, :invalid_credentials}
      end
  end

  @spec change_password(Joken.bearer_token(), binary(), binary()) ::
    {:ok, :password_changed} | {:error, :cannot_change_password}
  def change_password(access_token, current_password, new_password) when is_binary(current_password) and is_binary(new_password) do
    with {:ok, access_claims} <- TokenUtil.verify_access_token(access_token),
      {:ok, %UserSchema{} = user} <- get_user_by_identifier(access_claims["sub"]),
      true <- Argon2.verify_pass(current_password, user.password_hash),
      {:ok, _} <- Repository.update(UserSchema.change_password_changeset(user, %{password: new_password})) do
        {:ok, :password_changed}
    else
      false ->
        Argon2.no_user_verify()
        {:error, :cannot_change_password}
      _ ->
        {:error, :cannot_change_password}
    end
  end

  @spec get_user_by_identifier(pos_integer()) ::
    {:ok, UserSchema.t()} | {:error, :user_not_found}
  def get_user_by_identifier(identifier) when is_integer(identifier) and identifier > 0,
    do: fetch_user_by_query(from subject in UserSchema, where: subject.id == ^identifier)

  @spec get_user_by_identifier(binary()) ::
    {:ok, UserSchema.t()} | {:error, :user_not_found}
  def get_user_by_identifier(identifier) when is_binary(identifier) and byte_size(identifier) > 0 do
    if String.match?(identifier, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/),
      do: fetch_user_by_query(from subject in UserSchema, where: subject.email == ^identifier),
      else: fetch_user_by_query(from subject in UserSchema, where: subject.username == ^identifier)
  end

   # * === Helpers === * #
   @spec fetch_user_by_query(Ecto.Query.t()) ::
    {:ok, UserSchema.t()} | {:error, :user_not_found}
   defp fetch_user_by_query(%Ecto.Query{} = query) do
     case Repository.one(query) do
       %UserSchema{} = record ->
         {:ok, record}
       _ ->
         {:error, :user_not_found}
     end
   end
end
