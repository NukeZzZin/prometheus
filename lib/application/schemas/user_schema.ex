defmodule Prometheus.Schemas.UserSchema do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  @type t :: %__MODULE__{}

  schema "users" do
    field :username, :string
    field :display_name, :string
    field :user_flags, :integer, default: 0b0

    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    timestamps()
  end

  @spec create_user_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def create_user_changeset(%__MODULE__{} = changeset, attributes) do
    changeset
    |> cast(attributes, [:username, :display_name, :email, :password])
    |> validate_required([:username, :display_name, :email, :password])
    |> validate_username_field()
    |> validate_display_name_field()
    |> validate_email_field()
    |> validate_password_field()
    |> put_snowflake_id()
    |> put_password_hash()
  end

  @spec update_profile_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def update_profile_changeset(%__MODULE__{} = changeset, attributes) do
    changeset
    |> cast(attributes, [:username, :display_name, :email])
    |> validate_required([:username, :display_name, :email])
    |> validate_username_field()
    |> validate_display_name_field()
    |> validate_email_field()
  end

  @spec change_password_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def change_password_changeset(%__MODULE__{} = changeset, attributes) do
    changeset
    |> cast(attributes, [:password])
    |> validate_required([:password])
    |> validate_password_field()
    |> put_password_hash()
  end

  # ! === Private Helpers === ! #
  @spec validate_email_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_email_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> put_normalized_field(:email)
    |> validate_length(:email, min: 6, max: 320, message: "email must be between 6 and 320 characters")
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "invalid email format")
    |> unsafe_validate_unique(:email, Prometheus.Repository)
    |> unique_constraint(:email)
  end

  @spec validate_display_name_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_display_name_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_length(:display_name, min: 2, max: 64, message: "display name must be between 2 and 64 characters")
    |> validate_format(:display_name, ~r/^[^\p{Cc}\p{Cs}]+$/, message: "display name contains invalid characters")
  end

  @spec validate_username_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_username_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> put_normalized_field(:username)
    |> validate_length(:username, min: 4, max: 32, message: "username must be between 4 and 32 characters")
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "invalid username format")
    |> unsafe_validate_unique(:username, Prometheus.Repository)
    |> unique_constraint(:username)
  end

  @spec validate_password_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_password_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 64, message: "password must be between 8 and 64 characters")
    |> validate_format(:password, ~r/^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/, message: "invalid password format")
  end

  @spec put_password_hash(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :password) do
      plain_password when is_binary(plain_password) and byte_size(plain_password) > 0 ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(plain_password))
      _ ->
        changeset
    end
  end
  defp put_password_hash(changeset), do: changeset

  @spec put_snowflake_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_snowflake_id(%Ecto.Changeset{valid?: true} = changeset) do
    case get_field(changeset, :id) do
      nil ->
        case Snowflake.next_id() do
          {:ok, snowflake} ->
            put_change(changeset, :id, snowflake)
          {:error, :backwards_clock} ->
            add_error(changeset, :id, "failed to generate snowflake id (clock moved backwards)")
        end
      _ ->
        changeset
    end
  end
  defp put_snowflake_id(changeset), do: changeset

  @spec put_normalized_field(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp put_normalized_field(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    case get_field(changeset, field) do
      value when is_binary(value) ->
        normalized_string = value
        |> String.trim()
        |> String.downcase()
        |> String.normalize(:nfc)
        put_change(changeset, field, normalized_string)
      _ ->
        changeset
    end
  end
end

defimpl Jason.Encoder, for: Prometheus.Schemas.UserSchema do
  @spec encode(Prometheus.Schemas.UserSchema.t(), Jason.Encode.opts()) :: iodata()
  def encode(payload, options) do
    Jason.Encode.map(
      %{
        id: to_string(payload.id),
        username: payload.username,
        display_name: payload.display_name,
        email: payload.email,
        user_flags: to_string(payload.user_flags),
        inserted_at: payload.inserted_at,
        updated_at: payload.updated_at
      },
      options
    )
  end
end
