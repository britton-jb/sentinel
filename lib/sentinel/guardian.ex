defmodule Sentinel.Guardian do
  @moduledoc """
  Implements Sentinel's specific implementaiton of guardian, and guardianDb hooks
  """
  alias Sentinel.Config

  use Guardian, otp_app: Sentinel.Config.otp_app()

  def subject_for_token(resource, _claims) do
    struct_type = Config.user_model().__struct__

    if struct_type = resource.__struct__ do
      {:ok, to_string(resource.id)}
    else
      {:error, :unknown_resource_type}
    end
  end

  def resource_from_claims(claims) do
    resource = Config.repo.get(Config.user_model, String.to_integer(claims["sub"]))

    if is_nil(resource) do
      {:error, :unknown_resource_type}
    else
      {:ok, resource}
    end
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with true <- Config.guardian_db?(),
      {:ok, _} <- GuardianDb.after_encode_and_sign(resource, claims["typ"], claims, token) do
        {:ok, token}
    else
      _ -> {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with true <- Config.guardian_db?(),
      {:ok, _} <- GuardianDb.on_verify(claims, token) do
        {:ok, claims}
    else
      _ -> {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with true <- Config.guardian_db?(),
      {:ok, _} <- GuardianDb.on_revoke(claims, token) do
        {:ok, claims}
    else
      _ -> {:ok, claims}
    end
  end
end
