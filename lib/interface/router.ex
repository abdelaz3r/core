defmodule Interface.Router do
  use Interface, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Interface.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :core do
    scope "/", Interface do
      pipe_through([:browser])

      live("/", Live.Home)
    end
  end
end
