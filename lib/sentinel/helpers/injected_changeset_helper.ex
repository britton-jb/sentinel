defmodule Sentinel.Helpers.InjectedChangesetHelper do
  @moduledoc false

  def apply(nil, changeset, _params), do: changeset
  def apply({module, function}, changeset, params) do
    Kernel.apply(module, function, [changeset, params])
  end
  def apply(anon_function, changeset, params) do
    anon_function.(changeset, params)
  end
end
