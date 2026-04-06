defmodule Prometheus.Schemas.UserSchema do
  use Ecto.Schema
  import Ecto.Changeset
  alias Prometheus.Utils.SnowflakeUtil

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @display_name_regex ~r/^[\p{L}\p{N}\s._-]+$/u
  @username_regex ~r/^[a-z0-9_-]+$/
  @password_regex ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$/

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, only: [:id, :username, :display_name, :email]}

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
    |> SnowflakeUtil.put_changeset_snowflake_id()
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
    |> validate_format(:email, @email_regex, message: "invalid email format")
    |> unique_constraint(:email)
  end

  @spec validate_display_name_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_display_name_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_length(:display_name, min: 2, max: 64, message: "display name must be between 2 and 64 characters")
    |> validate_format(:display_name, @display_name_regex, message: "display name contains invalid characters")
  end

  @spec validate_username_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_username_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> put_normalized_field(:username)
    |> validate_length(:username, min: 4, max: 32, message: "username must be between 4 and 32 characters")
    |> validate_format(:username, @username_regex, message: "invalid username format")
    |> unique_constraint(:username)
  end

  @spec validate_password_field(%__MODULE__{} | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_password_field(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 64, message: "password must be between 8 and 64 characters")
    |> validate_format(:password, @password_regex, message: "invalid password format")
  end

  @spec put_password_hash(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
    end
  end
  defp put_password_hash(changeset), do: changeset

  @spec put_normalized_field(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp put_normalized_field(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    case get_field(changeset, field) do
      nil -> changeset
      value -> put_change(changeset, field, String.trim(String.normalize(String.downcase(value, :default), :nfc)))
    end
  end
end
