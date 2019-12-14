defmodule FTC.Display.PageController do
  use FTC.Display, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
