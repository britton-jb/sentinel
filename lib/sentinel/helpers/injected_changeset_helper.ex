defmodule Sentinel.Helpers.InjectedChangesetHelper do
  @moduledoc false

  def apply(changeset, nil,  _params), do: changeset
  def apply(changeset, {module, function}, params) do
    Kernel.apply(module, function, [changeset, params])
  end
  def apply(changeset, anon_function, params) do
    anon_function.(changeset, params)
  end
end
