defmodule WorldBuildWeb.Router do
  use WorldBuildWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WorldBuildWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WorldBuildWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", WorldBuildWeb do
    pipe_through :api

    post "/update_position", ApiController, :update_position
    get "/health", ApiController, :health
    post "/join", ApiController, :join_world
    get "/world", ApiController, :world_state
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:world_build, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WorldBuildWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
