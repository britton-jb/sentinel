defmodule Sentinel.LayoutView do
  use Phoenix.View, root: "lib/sentinel/web/templates/"
  import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
  use Phoenix.HTML

  alias Sentinel.Config
end
