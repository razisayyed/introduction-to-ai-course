defmodule AiCourseWeb.SimulatedAnnealingTSPLive do
  use AiCourseWeb, :live_view
  alias SimulatedAnnealing.Solver
  alias SimulatedAnnealing.Examples.TSP
  alias SimulatedAnnealing.Options

  def mount(_params, _session, socket) do
    # if connected?(socket), do: :timer.send_interval(500, self(), :tick)

    state =
      Solver.initialize(
        TSP,
        %Options{
          problem_opts: [cities_count: 25]
        }
      )

    fields = %{
      "cities_count" => 10,
      "delay" => 0,
      "initial_temperature" => 20,
      "cooling_function" => "blotzmann",
      "cooling_rate" => 0.9995,
      "max_iterations" => 1000_000,
      "max_reannealing_iterations" => 0,
      "min_temperature" => 0
    }

    {
      :ok,
      socket
      |> assign(form: to_form(fields))
      |> assign(state: state)
      |> assign(running: false)
      |> assign(active_link: :tsp_sa)
    }
  end

  def handle_info(:tick, socket) do
    {status, state} =
      if socket.assigns.delay < 5 do
        1..500
        |> Enum.reduce({:ok, socket.assigns.state}, fn _i, {_prev_status, prev_state} ->
          Solver.next_state(
            prev_state,
            TSP,
            socket.assigns.opts
          )
        end)
      else
        Solver.next_state(
          socket.assigns.state,
          TSP,
          socket.assigns.opts
        )
      end

    if status == :terminate or socket.assigns.running == false do
      # :timer.cancel(socket.assigns.timerRef)

      {:noreply,
       socket
       |> assign(running: false)
       |> assign(state: state)
       |> assign(ellapsed_time: System.monotonic_time(:millisecond) - socket.assigns.start_time)}
    else
      case socket.assigns.delay do
        0 -> send(self(), :tick)
        _ -> {:ok, _timerRef} = :timer.send_after(socket.assigns.delay, self(), :tick)
      end

      {:noreply,
       socket
       |> assign(state: state)
       |> assign(ellapsed_time: System.monotonic_time(:millisecond) - socket.assigns.start_time)}
    end
  end

  def handle_event("validate", params, socket) do
    # socket.assigns.form
    # errors = [max_generations: "Maximum Generations must be a number"]

    # {:noreply, socket |> assign(:form, to_form(params, errors: errors))}
    {:noreply, socket |> assign(:form, to_form(params))}
  end

  def handle_event("start", params, socket) do
    # Generate a new population

    opts = %Options{
      initial_temperature: Float.parse(params["initial_temperature"]) |> elem(0),
      cooling_rate: Float.parse(params["cooling_rate"]) |> elem(0),
      max_iterations: Integer.parse(params["max_iterations"]) |> elem(0),
      max_reannealing_iterations: Integer.parse(params["max_reannealing_iterations"]) |> elem(0),
      min_temperature: Float.parse(params["min_temperature"]) |> elem(0),
      cooling_function: String.to_existing_atom(params["cooling_function"]),
      problem_opts: [cities_count: Integer.parse(params["cities_count"]) |> elem(0)]
    }

    delay = Integer.parse(params["delay"]) |> elem(0)

    state = Solver.initialize(TSP, opts)

    # {:ok, timerRef} = :timer.send_interval(delay, self(), :tick)
    # {:ok, _timerRef} = :timer.send_after(delay, self(), :tick)
    send(self(), :tick)

    {:noreply,
     socket
     |> assign(opts: opts)
     |> assign(delay: delay)
     |> assign(state: state)
     |> assign(running: true)
     |> assign(start_time: System.monotonic_time(:millisecond))
     |> assign(ellapsed_time: System.monotonic_time(:millisecond))}
  end

  def handle_event("stop", _params, socket) do
    # :timer.cancel(socket.assigns.timerRef)
    {:noreply, socket |> assign(running: false)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-100 p-3">
        <.simple_form id="settings" for={@form} phx-change="validate" phx-submit="start">
          <div class="grid grid-cols-5 items-end gap-6">
            <.input type="number" field={@form[:initial_temperature]} label="Initial Temperature" />
            <.input
              type="select"
              field={@form[:cooling_function]}
              label="Cooling Function"
              options={[
                {"Fast Cooling", "fast_cooling"},
                {"Boltzmann", "blotzmann"},
                {"Exponential", "exponential_cooling"}
              ]}
            />
            <.input type="number" field={@form[:cooling_rate]} label="Cooling Rate" />
            <.input type="number" field={@form[:max_iterations]} label="Max Iterations" />
            <.input
              type="number"
              field={@form[:max_reannealing_iterations]}
              label="Max Reannealing Iterations"
            />
            <.input type="number" field={@form[:min_temperature]} label="Min Temperature" />
            <.input
              type="select"
              field={@form[:cities_count]}
              label="Cities Count"
              options={10..25 |> Enum.map(fn i -> {"#{i}", i} end) |> Enum.to_list()}
            />
            <.input
              type="select"
              field={@form[:delay]}
              label="Delay (ms)"
              options={[
                {"0 ms", 0},
                {"5 ms", 5},
                {"10 ms", 10},
                {"20 ms", 20},
                {"50 ms", 50},
                {"100 ms", 100},
                {"200 ms", 200},
                {"500 ms", 500},
                {"1000 ms", 1000}
              ]}
            />
            <div class="grid grid-cols-2 gap-2">
              <.button
                phx-disable-with="Calculating..."
                class="bg-blue-500 text-white px-4 py-2 rounded-lg"
              >
                Start
              </.button>
              <.button
                type="button"
                phx-click="stop"
                class="bg-red-500 text-white px-4 py-2 rounded-lg"
              >
                Stop
              </.button>
            </div>
          </div>
        </.simple_form>
      </div>
      <%= if @state.iteration > 0 do %>
        <div class="grid grid-cols-3 gap-6 mt-4">
          <div
            class="bg-cover bg-center w-full aspect-[245/625]"
            style={"background-image: url('#{~p"/images/palestine.png"}');"}
          >
            <.tsp_map cities={@state.best} />
          </div>
          <div>
            <div class="bg-gray-100 rounded p-3 mb-3">
              <h2>Best Energy: <%= Float.round(@state.best_energy, 2) %></h2>
              <h2>Current Energy: <%= Float.round(@state.current_energy, 2) %></h2>
              <h2>Temperature: <%= :io_lib.format("~e", [@state.temperature]) %></h2>
              <h2>Iteration: <%= @state.iteration %></h2>
              <h2>Annealing Iteration: <%= @state.annealing_iteration %></h2>
              <h2>Ellapsed Time: <%= @ellapsed_time %></h2>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
