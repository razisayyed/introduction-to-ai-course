defmodule AiCourse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiCourseWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:ai_course, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AiCourse.PubSub},
      # Start a worker by calling: AiCourse.Worker.start_link(arg)
      # {AiCourse.Worker, arg},
      # Start to serve requests, typically the last entry
      AiCourseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiCourse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiCourseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
