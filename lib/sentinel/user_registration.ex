defmodule Sentinel.UserRegistration do
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.UserHelper
  alias Sentinel.PasswordResetter

  @doc """
  Registration with email
  """
  def register(conn, params = %{"user" => %{"email" => email}}) when email != "" and email != nil do
    {confirmation_token, changeset} =
      Registrator.changeset(params["user"])
      |> Confirmator.confirmation_needed_changeset

    if changeset.valid? do
      case Util.repo.transaction fn ->
        Util.repo.insert!(changeset)
      end do
        {:ok, user} ->
          confirmable_and_invitable(conn, user, confirmation_token)
      end
    else
      {:error, Enum.into(changeset.errors, %{})}
    end
  end

  @doc """
  Registration with username
  """
  def register(conn, params = %{"user" => %{"username" => username}}) when username != "" and username != nil do
    changeset = Registrator.changeset(params["user"])

    if changeset.valid? do
      case Util.repo.transaction fn ->
        Util.repo.insert(changeset)
      end do
        {:ok, user} ->
          confirmable_and_invitable(conn, user, "")
      end
    else
      Util.send_error(conn, Enum.into(changeset.errors, %{}))
    end
  end

  @doc """
  Invalid user parameters
  """
  def register(conn, params) do
    changeset = Registrator.changeset(params["user"])
    {:error, Enum.into(changeset.errors, %{})}
  end

  def confirm(conn, params = %{"id" => user_id, "confirmation_token" => _}) do
    user = Util.repo.get!(UserHelper.model, user_id)
    changeset = Confirmator.confirmation_changeset(user, params)

    if changeset.valid? do
      user = Util.repo.update!(changeset)
      encode_and_sign(conn, user)
    else
      {:error, Enum.into(changeset.errors, %{})}
    end
  end

  def invited(conn, params) do
    user_id = params["id"]

    user = Util.repo.get!(UserHelper.model, user_id)
    user_params = Map.merge(params, %{
      "id" => user.id,
      "email" => user.email
    })
    changeset = PasswordResetter.reset_changeset(user, params)

    if changeset.valid? do
      user = Util.repo.update!(changeset)

      changeset = Confirmator.confirmation_changeset(user, params)
      user = Util.repo.update!(changeset)
      encode_and_sign(conn, user)
    else
      {:error, Enum.into(changeset.errors, %{})}
    end
  end

  defp confirmable_and_invitable(conn, user, confirmation_token) do
    case {is_confirmable, is_invitable} do
      {false, false} ->
        encode_and_sign(conn, user) # not confirmable or invitable - just log them in

      {_confirmable, :true} -> # must be invited
        {password_reset_token, changeset} = PasswordResetter.create_changeset(user)

        if changeset.valid? do
          user = Util.repo.update!(changeset)
        end

        Mailer.send_invite_email(user, {confirmation_token, password_reset_token})

        {:ok, :needs_invitation}

      {:required, _invitable} -> # must be confirmed
        Mailer.send_welcome_email(user, confirmation_token)

        {:ok, :needs_confirmation}

      {_confirmable_default, _invitable} -> # default behavior, optional confirmable, not invitable
        Mailer.send_welcome_email(user, confirmation_token)
        encode_and_sign(conn, user)
    end
  end


  defp encode_and_sign(conn, user) do
    permissions = UserHelper.model.permissions(user.role)

    case Guardian.encode_and_sign(user, :token, permissions) do
      {:ok, token, claims} -> conn
        {:ok, user, token, claims}
      {:error, :token_storage_failure} ->
        {:error, "Failed to store session, please try to login again using your new password"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp is_confirmable do
    case Application.get_env(:sentinel, :confirmable) do
      :required -> :required
      :false -> :false
      _ -> :optional
    end
  end

  defp is_invitable do
    Application.get_env(:sentinel, :invitable) || :false
  end
end
