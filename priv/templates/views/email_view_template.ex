defmodule <%= module %> do
  use Phoenix.View, root: "<%= templates_path %>", namespace: Bamboo.EmailView
  use Phoenix.HTML

  alias Sentinel.Config
end
