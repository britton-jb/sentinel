defmodule Sentinel.TestRepo do
  use Ecto.Repo, otp_app: :sentinel

  def log(_cmd), do: nil
end
