defmodule Sentinel.EmailLayoutView do
  use Phoenix.View, root: "lib/sentinel/templates/"
  import Phoenix.Controller, only: [view_module: 1]
  use Phoenix.HTML
  import Sentinel.RouterHelper
end
