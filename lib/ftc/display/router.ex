defmodule FTC.Display.Router do
  use FTC.Display, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FTC.Display do
    pipe_through :browser

    live "/", StatusLive

    get "/settings", SettingsController, :index
    post "/settings", SettingsController, :update
  end
end
