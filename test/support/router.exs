defmodule Sentinel.TestRouter do
  use Phoenix.Router
  require Sentinel

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser
    Sentinel.mount_html
  end

  #FIXME do I need this router to have two modules,
  # one each set using mix config in the tests as needed?
  #scope "/" do
  #  pipe_through :api
  #  Sentinel.mount_api
  #end
end
