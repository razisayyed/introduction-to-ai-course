defmodule AiCourseWeb.Router do
  use AiCourseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AiCourseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AiCourseWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/genetic-algorithms-nqueens", GeneticAlgorithmNQueensLive, :demo
    live "/genetic-algorithms-tsp", GeneticAlgorithmTSPLive, :demo
    live "/genetic-algorithms-graph-coloring", GeneticAlgorithmGraphColoringLive, :demo

    live "/simulated-annealing-nqueens", SimulatedAnnealingNQueensLive, :demo
    live "/simulated-annealing-tsp", SimulatedAnnealingTSPLive, :dem
    live "/simulated-annealing-graph-coloring", SimulatedAnnealingGraphColoringLive, :demo
  end

  # Other scopes may use custom stacks.
  # scope "/api", AiCourseWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:ai_course, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AiCourseWeb.Telemetry
    end
  end
end
