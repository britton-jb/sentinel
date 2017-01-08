defmodule Sentinel.EmailView do
  use Phoenix.View, root: "lib/sentinel/web/templates/email/", namespace: Bamboo.EmailView
  use Phoenix.HTML

  alias Sentinel.Config
end
