defmodule AiCourseWeb.GeneticAlgorithmTSPLive do
  use AiCourseWeb, :live_view
  alias GeneticAlgorithms.Solver
  alias GeneticAlgorithms.Examples.TSP

  def mount(_params, _session, socket) do
    # if connected?(socket), do: :timer.send_interval(500, self(), :tick)

    population =
      Solver.init(
        TSP,
        problem_opts: [
          cities_count: 10
        ]
      )

    fields = %{
      "max_generations" => 1000,
      "population_size" => 100,
      "cities_count" => 25,
      "selection_rate" => 0.5,
      "mutation_rate" => 0.2,
      "delay" => 50,
      "crossover_type" => "single_point",
      "selection_type" => "steady_state"
    }

    {
      :ok,
      socket
      |> assign(form: to_form(fields))
      |> assign(population: population)
      |> assign(best: nil)
      |> assign(generation: 0)
      |> assign(running: false)
      |> assign(active_link: :tsp_ga)
    }
  end

  def handle_info(:tick, socket) do
    {status, population, best, generation} =
      Solver.next_generation(
        socket.assigns.population,
        TSP,
        socket.assigns.generation,
        socket.assigns.best,
        socket.assigns.opts
      )

    if status == :terminate or socket.assigns.running == false do
      # :timer.cancel(socket.assigns.timerRef)

      {:noreply,
       socket
       |> assign(running: false)
       |> assign(population: population)
       |> assign(best: best)
       |> assign(generation: generation)
       |> assign(ellapsed_time: System.monotonic_time(:millisecond) - socket.assigns.start_time)}
    else
      case socket.assigns.delay do
        0 -> send(self(), :tick)
        _ -> {:ok, _timerRef} = :timer.send_after(socket.assigns.delay, self(), :tick)
      end

      {:noreply,
       socket
       |> assign(population: population)
       |> assign(best: best)
       |> assign(generation: generation)
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

    opts = [
      population_size: Integer.parse(params["population_size"]) |> elem(0),
      selection_rate: Float.parse(params["selection_rate"]) |> elem(0),
      mutation_rate: Float.parse(params["mutation_rate"]) |> elem(0),
      crossover_type: String.to_existing_atom(params["crossover_type"]),
      selection_type: String.to_existing_atom(params["selection_type"]),
      problem_opts: [
        max_generations: Integer.parse(params["max_generations"]) |> elem(0),
        cities_count: Integer.parse(params["cities_count"]) |> elem(0)
      ]
    ]

    delay = Integer.parse(params["delay"]) |> elem(0)

    population = Solver.init(TSP, opts)

    # {:ok, timerRef} = :timer.send_interval(delay, self(), :tick)
    #  :timer.send_after(delay, self(), :tick)
    # {:ok, _timerRef} = send(self(), :tick)
    send(self(), :tick)

    {:noreply,
     socket
     |> assign(opts: opts)
     |> assign(delay: delay)
     |> assign(population: population)
     |> assign(best: nil)
     |> assign(generation: 0)
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
          <div class="grid grid-cols-4 items-end gap-6">
            <.input type="number" field={@form[:max_generations]} label="Maximum Generations" />
            <.input type="number" field={@form[:population_size]} label="Population Size" />
            <.input type="number" field={@form[:cities_count]} label="Cities Count" />
            <.input type="number" field={@form[:selection_rate]} label="Selection Rate" />
            <.input type="number" field={@form[:mutation_rate]} label="Mutation Rate" />
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
            <.input
              type="select"
              field={@form[:crossover_type]}
              label="Crossover Type"
              options={[
                {"Single Point", "single_point"},
                {"Two Points", "two_point"},
                {"Uniform", "uniform"},
                {"Partially Mapped", "pmx"}
              ]}
            />
            <.input
              type="select"
              field={@form[:selection_type]}
              label="Selection Type"
              options={[
                {"Steady State", "steady_state"},
                {"Roulette Wheel", "roulette_wheel"},
                {"Tournament", "tournament"}
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
      <%= if assigns.best do %>
        <div class="grid grid-cols-3 gap-6 mt-4 mb-3">
          <div
            class="bg-cover bg-center w-full aspect-[245/625]"
            style={"background-image: url('#{~p"/images/palestine.png"}');"}
          >
            <%!-- <%= raw(GeneticAlgorithms.Examples.TSP.board_as_svg(@best)) %> --%>
            <.tsp_map cities={@best.genes} />
          </div>
          <div class="col-span-2">
            <div class="grid grid-cols-2 gap-6">
              <div class="bg-gray-100 rounded p-3">
                <h2>Generation: <%= @generation %></h2>
                <h2>Ellapsed Time: <%= @ellapsed_time %></h2>
                <div class="text-red-600 font-bold">
                  Convergence: <%= Enum.reduce(@population, 0, fn c, acc ->
                    if c.fitness == @best.fitness, do: 1 + acc, else: acc
                  end) %>
                </div>
              </div>
              <div class="bg-gray-100 rounded p-3">
                <h2>Best Fitness: <%= @best.fitness |> Float.ceil(2) %></h2>
                <h2>Best Solution Age: <%= @best.age %></h2>
                <h2>Crossovers Count: <%= @best.crossovers_count %></h2>
                <h2>Mutations Count: <%= @best.mutations_count %></h2>
              </div>
            </div>

            <%!-- <table class="table-auto">
              <thead>
                <tr>
                  <th class="px-4 py-2">Fitness</th>
                  <th class="px-4 py-2">Chromosomes</th>
                </tr>
              </thead>
              <tbody>
                <%= for {fitness, chromosomes} <- Enum.group_by(@population, & &1.fitness) do %>
                  <tr>
                    <td class="border px-4 py-2"><%= fitness %></td>
                    <td class="border px-4 py-2"><%= Enum.count(chromosomes) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table> --%>
            <table class="table w-full">
              <thead>
                <tr>
                  <th class="px-4 py-2">Fitness</th>
                  <th class="px-4 py-2">Age</th>
                  <th class="px-4 py-2">Crossovers</th>
                  <th class="px-4 py-2">Mutations</th>
                </tr>
              </thead>
              <tbody>
                <%= for chromosome <- @population |> Enum.take(10) do %>
                  <tr>
                    <td class="border px-4 py-2"><%= chromosome.fitness |> Float.ceil(2) %></td>
                    <td class="border px-4 py-2"><%= chromosome.age %></td>
                    <td class="border px-4 py-2"><%= chromosome.crossovers_count %></td>
                    <td class="border px-4 py-2"><%= chromosome.mutations_count %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
