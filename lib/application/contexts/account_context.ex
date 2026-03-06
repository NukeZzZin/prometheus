defmodule Prometheus.Contexts.AccountContext do
  import Ecto.Query
  alias Prometheus.{Repository, Contexts.SessionContext, Schemas.UserSchema}

  @spec register_user(map()) :: {:ok, %{access_token: binary(), refresh_token: binary()}} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def register_user(attributes) when is_map(attributes) do
    case Repository.insert(UserSchema.create_user_changeset(%UserSchema{}, attributes)) do
      {:ok, %UserSchema{} = account} ->
        SessionContext.create_session(account.id)
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  @spec login_user(pos_integer() | binary(), binary())   :: {:ok, %{access_token: binary(), refresh_token: binary()}} | {:error, atom()}
  def login_user(identifier, password_plain) when (is_integer(identifier) or is_binary(identifier)) and is_binary(password_plain) do
    case get_user_by_identifier(identifier) do
      {:ok, %UserSchema{} = account} ->
        if Argon2.verify_pass(password_plain, account.password_hash),
          do: SessionContext.create_session(account.id),
          else: {:error, :invalid_credentials}
      {:error, :user_not_found} ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @spec get_user_by_identifier(pos_integer()) :: {:ok, UserSchema.t()} | {:error, atom()}
  def get_user_by_identifier(identifier) when is_integer(identifier),
    do: fetch_user_by_query(from subject in UserSchema, where: subject.id == ^identifier)

  @spec get_user_by_identifier(binary()) :: {:ok, UserSchema.t()} | {:error, atom()}
  def get_user_by_identifier(identifier) when is_binary(identifier) do
    if String.match?(identifier, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/),
      do: fetch_user_by_query(from subject in UserSchema, where: subject.email == ^identifier),
      else: fetch_user_by_query(from subject in UserSchema, where: subject.username == ^identifier)
  end

   # * === Helpers === * #
   @spec fetch_user_by_query(Ecto.Query.t()) :: {:ok, UserSchema.t()} | {:error, atom()}
   defp fetch_user_by_query(%Ecto.Query{} = query) do
     case Repository.one(query) do
       %UserSchema{} = record ->
         {:ok, record}
       _ ->
         {:error, :user_not_found}
     end
   end
end
