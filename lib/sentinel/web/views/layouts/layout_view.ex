defmodule Sentinel.LayoutView do
  use Phoenix.View, root: "lib/sentinel/web/templates/"
  import Phoenix.Controller, only: [get_flash: 2]
  use Phoenix.HTML

  alias Sentinel.Config
end
