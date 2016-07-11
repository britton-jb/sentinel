defmodule SentinelTester.ErrorView do
  use Phoenix.View, root: "lib/sentinel/templates/"
  import Phoenix.Controller, only: [view_module: 1]
  use Phoenix.HTML
  import Sentinel.RouterHelper

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Server internal error"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
