defmodule AiCourseWeb.GeneticAlgorithmGraphColoringLive do
  use AiCourseWeb, :live_view

  alias GeneticAlgorithms.Solver
  alias GeneticAlgorithms.Examples.GraphColoring
  alias GeneticAlgorithms.Examples.GraphColoring.Node

  def mount(_params, _session, socket) do
    population =
      Solver.init(
        GraphColoring,
        problem_opts: [
          nodes: [],
          colors_count: 3
        ]
      )

    fields = %{
      "max_generations" => 1000,
      "population_size" => 100,
      "selection_rate" => 0.5,
      "mutation_rate" => 0.1,
      "delay" => 0,
      "crossover_type" => "pmx",
      "selection_type" => "roulette_wheel",
      "colors_count" => 3
    }

    {
      :ok,
      socket
      |> assign(form: to_form(fields))
      |> assign(population: population)
      |> assign(best: nil)
      |> assign(generation: 0)
      |> assign(running: false)
      |> assign(:nodes, [])
      |> assign(:mode, :nodes)
      |> assign(:selected_node, nil)
      |> assign(:active_link, :graph_coloring_ga)
    }
  end

  def handle_info(:tick, socket) do
    {status, population, best, generation} =
      if socket.assigns.delay < 5 do
        1..20
        |> Enum.reduce(
          {:ok, socket.assigns.population, socket.assigns.best, socket.assigns.generation},
          fn _i, {_prev_status, population, best, generation} ->
            Solver.next_generation(
              population,
              GraphColoring,
              generation,
              best,
              socket.assigns.opts
            )
          end
        )
      else
        Solver.next_generation(
          socket.assigns.population,
          GraphColoring,
          socket.assigns.generation,
          socket.assigns.best,
          socket.assigns.opts
        )
      end

    nodes =
      0..(length(best.genes) - 1)
      |> Enum.map(fn i ->
        {_, x, y} = Enum.at(socket.assigns.nodes, i)
        node = Enum.at(best.genes, i)

        {node, x, y}
      end)

    if status == :terminate or socket.assigns.running == false do
      {:noreply,
       socket
       |> assign(mode: :nodes)
       |> assign(nodes: nodes)
       |> assign(running: false)
       |> assign(population: population)
       |> assign(best: best)
       |> assign(generation: generation)
       |> assign(ellapsed_time: get_ellapsed_time_in_ms(socket))}
    else
      case socket.assigns.delay do
        0 -> send(self(), :tick)
        _ -> {:ok, _timerRef} = :timer.send_after(socket.assigns.delay, self(), :tick)
      end

      {:noreply,
       socket
       |> assign(nodes: nodes)
       |> assign(population: population)
       |> assign(best: best)
       |> assign(generation: generation)
       |> assign(ellapsed_time: get_ellapsed_time_in_ms(socket))}
    end
  end

  def handle_event("validate", params, socket) do
    errors = []

    {:noreply, socket |> assign(:form, to_form(params, errors: errors))}
  end

  def handle_event("start", params, socket) do
    # Generate a new population

    opts = [
      max_generations: Integer.parse(params["max_generations"]) |> elem(0),
      population_size: Integer.parse(params["population_size"]) |> elem(0),
      selection_type: String.to_existing_atom(params["selection_type"]),
      crossover_type: String.to_existing_atom(params["crossover_type"]),
      selection_rate: Float.parse(params["selection_rate"]) |> elem(0),
      mutation_rate: Float.parse(params["mutation_rate"]) |> elem(0),
      problem_opts: [
        colors_count: Integer.parse(params["colors_count"]) |> elem(0),
        nodes: Enum.map(socket.assigns.nodes, fn {node, _, _} -> node end),
        max_generations: Integer.parse(params["max_generations"]) |> elem(0)
      ]
    ]

    delay = Integer.parse(params["delay"]) |> elem(0)

    population = Solver.init(GraphColoring, opts)

    # {:ok, timerRef} = :timer.send_interval(delay, self(), :tick)
    # {:ok, _timerRef} = :timer.send_after(delay, self(), :tick)
    send(self(), :tick)

    {:noreply,
     socket
     |> assign(opts: opts)
     |> assign(delay: delay)
     |> assign(population: population)
     |> assign(best: nil)
     |> assign(generation: 0)
     |> assign(running: true)
     |> assign(start_time: System.monotonic_time(:nanosecond))
     |> assign(ellapsed_time: System.monotonic_time(:nanosecond))}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, socket |> assign(mode: :nodes) |> assign(running: false)}
  end

  def handle_event("set_mode", params, socket) do
    if socket.assigns.mode == :running do
      {:noreply, socket}
    else
      mode = String.to_existing_atom(params["mode"])

      {:noreply,
       socket
       |> assign(:mode, mode)
       |> assign(:selected_node, nil)}
    end
  end

  def handle_event("cell_clicked", params, socket) do
    {:noreply, socket} = handle_cell_clicked(params, socket, socket.assigns.mode)

    {:noreply, socket}
  end

  def handle_event("load_preset", params, socket) do
    preset = Integer.parse(params["preset"]) |> elem(0)

    {nodes, _} = preset(preset)

    {:noreply, socket |> assign(:nodes, nodes)}
  end

  def handle_cell_clicked(params, socket, :nodes) do
    # Get the index of the node
    x = Integer.parse(params["x"]) |> elem(0)
    y = Integer.parse(params["y"]) |> elem(0)

    index = Enum.find_index(socket.assigns.nodes, fn {_, x2, y2} -> x == x2 and y == y2 end)

    nodes =
      case index do
        nil ->
          node = %Node{color: "white", edges: []}
          socket.assigns.nodes ++ [{node, x, y}]

        _ ->
          socket.assigns.nodes
          |> List.replace_at(index, {nil, nil, nil})
          |> Enum.map(fn {node, x, y} ->
            case node do
              nil ->
                {nil, nil, nil}

              _ ->
                node = %Node{node | edges: Enum.filter(node.edges, fn e -> e != index end)}
                {node, x, y}
            end
          end)
      end

    {:noreply, socket |> assign(:nodes, nodes)}
  end

  def handle_cell_clicked(params, socket, :edges) do
    index = Integer.parse(params["index"]) |> elem(0)

    case socket.assigns.selected_node do
      nil ->
        {:noreply, socket |> assign(:selected_node, index)}

      selected_node ->
        {index1, index2} =
          case index > selected_node do
            true -> {selected_node, index}
            false -> {index, selected_node}
          end

        {node, x, y} = Enum.at(socket.assigns.nodes, index1)

        node =
          case(Enum.member?(node.edges, index2)) do
            true ->
              %Node{node | edges: Enum.filter(node.edges, fn e -> e != index2 end)}

            false ->
              %Node{node | edges: [index2 | node.edges]}
          end

        nodes = List.replace_at(socket.assigns.nodes, index1, {node, x, y})

        {:noreply,
         socket
         |> assign(:nodes, nodes)
         |> assign(:selected_node, nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-7 items-stretch gap-3 mb-3">
      <div class="bg-gray-100 p-3 order-1 md:order-1 md:col-span-7 lg:col-span-2">
        <.simple_form id="settings" for={@form} phx-change="validate" phx-submit="start">
          <div class="grid grid-cols-4 lg:grid-cols-2 items-end gap-3">
            <.input type="number" field={@form[:max_generations]} label="Max Gens" />
            <.input type="number" field={@form[:population_size]} label="Population Size" />
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
            <.input type="number" field={@form[:selection_rate]} label="Selection Rate" />
            <.input type="number" field={@form[:mutation_rate]} label="Mutation Rate" />
            <.input
              type="select"
              field={@form[:colors_count]}
              label="Colors Count"
              options={3..20 |> Enum.map(&{&1, &1})}
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
            <%!-- <.input type="number" field={@form[:delay]} label="Delay (ms)" /> --%>
            <.button
              phx-disable-with="Calculating..."
              class="bg-blue-500 hover:bg-blue-700 text-white px-4 py-2 rounded-lg"
            >
              Start
            </.button>
            <.button
              type="button"
              phx-click="stop"
              class="bg-red-500 hover:bg-red-700 text-white px-4 py-2 rounded-lg"
            >
              Stop
            </.button>
          </div>
        </.simple_form>
      </div>
      <div class="order-3 md:order-2 md:col-span-4 lg:col-span-3">
        <div class="w-full relative bg-gray-100">
          <.coloring_graph nodes={@nodes} selected_node={@selected_node} />
          <%= if @mode == :nodes do %>
            <div class="absolute inset-0 grid grid-cols-[repeat(31,_minmax(0,_1fr))]">
              <%= for row <- 0..30 do %>
                <%= for col <- 0..30 do %>
                  <div
                    class="aspect-square hover:bg-gray-700/30 cursor-pointer rounded-full"
                    phx-click="cell_clicked"
                    phx-value-x={col}
                    phx-value-y={row}
                  >
                  </div>
                <% end %>
              <% end %>
            </div>
          <% end %>
          <%= if @mode == :edges do %>
            <div class="absolute inset-0 grid grid-cols-[repeat(31,_minmax(0,_1fr))]">
              <%= for row <- 0..30 do %>
                <%= for col <- 0..30 do %>
                  <% index = Enum.find_index(@nodes, fn {_, x, y} -> x == col and y == row end) %>
                  <%= if index != nil do %>
                    <div
                      class="aspect-square cursor-pointer rounded-full"
                      phx-click="cell_clicked"
                      phx-value-index={index}
                    >
                    </div>
                  <% else %>
                    <div class="aspect-square"></div>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
        <div class="bg-gray-100 py-3 w-full flex items-center gap-2 mt-2 px-3">
          <span>Add</span>
          <.button
            phx-click="set_mode"
            phx-value-mode="nodes"
            class={
              ["text-white", "font-bold", "py-2", "px-4", "rounded"] ++
                [
                  if(@mode == :nodes,
                    do: "bg-blue-500 hover:bg-blue-700",
                    else: "bg-zinc-900 hover:bg-zinc-700"
                  )
                ]
            }
          >
            Nodes
          </.button>
          <.button
            phx-click="set_mode"
            phx-value-mode="edges"
            class={
              ["text-white", "font-bold", "py-2", "px-4", "rounded"] ++
                [
                  if(@mode == :edges,
                    do: "bg-blue-500 hover:bg-blue-700",
                    else: "bg-zinc-900 hover:bg-zinc-700"
                  )
                ]
            }
          >
            Edges
          </.button>
        </div>
      </div>
      <div class="bg-gray-100 p-3 order-2 md:order-3 md:col-span-3 lg:col-span-2">
        <%!-- <h2 class="text-lg font-bold">Output</h2> --%>
        <div class="grid grid-cols-3 md:grid-cols-1 gap-x-2 gap-y-1">
          <%= if @generation > 0 do %>
            <div class="flex flex-col">
              <div>Best Fitness:</div>
              <div class="font-bold"><%= @best.fitness %></div>
            </div>
            <div class="flex flex-col">
              <div>Generation:</div>
              <div class="font-bold"><%= @generation %></div>
            </div>
            <div class="flex flex-col">
              <div>Ellapsed Time:</div>
              <div class="font-bold"><%= @ellapsed_time %>ms</div>
            </div>
            <div class="flex flex-col text-red-600 font-bold">
              <div>
                Convergence:
              </div>
              <div class="font-bold">
                <%= Enum.reduce(@population, 0, fn c, acc ->
                  if c.fitness == @best.fitness, do: 1 + acc, else: acc
                end) %>
              </div>
            </div>
          <% else %>
            <div class="flex flex-col">
              <div>Best Fitness:</div>
              <div class="font-bold">?</div>
            </div>
            <div class="flex flex-col">
              <div>Generation:</div>
              <div class="font-bold">?</div>
            </div>
            <div class="flex flex-col">
              <div>Ellapsed Time:</div>
              <div class="font-bold">?</div>
            </div>
            <div class="flex flex-col text-red-600 font-bold">
              <div>Convergence:</div>
              <div class="font-bold">?</div>
            </div>
          <% end %>
        </div>
      </div>
      <div class="grid grid-cols-3 md:grid-cols-6 gap-3 mb-3 order-4 md:col-span-7">
        <%= for i <- 0..5 do %>
          <div
            class="bg-gray-100 cursor-pointer hover:bg-gray-200"
            phx-click="load_preset"
            phx-value-preset={i}
          >
            <% preset = preset(i) %>
            <.coloring_graph nodes={preset |> elem(0)} />
            <%= if preset |> elem(1) > 0 do %>
              <h2 class="text-center">Min colors: <%= preset |> elem(1) %></h2>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    <div class="p-3 bg-gray-100">
      <h2 class="text-lg font-bold mb-3">Graph Coloring</h2>
      <p class="mb-3">
        Graph coloring is a classic problem in computer science. The problem is to assign colors to the vertices of a graph in such a way that no two adjacent vertices share the same color.
      </p>
      <p class="mb-3">
        The problem is NP-complete, which means that there is no known polynomial-time algorithm that can solve all instances of the problem. However, there are many heuristic algorithms that can find good solutions to the problem in a reasonable amount of time.
      </p>
      <p class="mb-3">
        One such algorithm is simulated annealing. Simulated annealing is a probabilistic optimization algorithm that is inspired by the process of annealing in metallurgy. The algorithm starts with an initial solution and iteratively improves the solution by making random changes to it. The algorithm uses a temperature parameter to control the probability of accepting a worse solution, which allows it to escape local optima and explore the solution space more thoroughly.
      </p>
    </div>
    """
  end

  def preset(0) do
    {
      [],
      0
    }
  end

  def preset(1) do
    {
      [
        {%Node{color: "white", edges: [1, 2, 3]}, 15, 2},
        {%Node{color: "white", edges: [6, 7]}, 15, 7},
        {%Node{color: "white", edges: [4, 8]}, 2, 13},
        {%Node{color: "white", edges: [5, 9]}, 28, 13},
        {%Node{color: "white", edges: [5, 7]}, 6, 14},
        {%Node{color: "white", edges: [6]}, 24, 14},
        {%Node{color: "white", edges: [8]}, 9, 25},
        {%Node{color: "white", edges: [9]}, 20, 25},
        {%Node{color: "white", edges: [9]}, 7, 28},
        {%Node{color: "white", edges: []}, 22, 28}
      ],
      3
    }
  end

  def preset(2) do
    {
      [
        {%Node{color: "white", edges: [1, 4]}, 2, 2},
        {%Node{color: "white", edges: [2, 3, 4, 5]}, 15, 2},
        {%Node{color: "white", edges: [5]}, 28, 2},
        {%Node{color: "white", edges: [8, 9]}, 15, 7},
        {%Node{color: "white", edges: [6, 10, 11]}, 2, 13},
        {%Node{color: "white", edges: [7, 12, 13]}, 28, 13},
        {%Node{color: "white", edges: [9]}, 6, 14},
        {%Node{color: "white", edges: [8, 6]}, 24, 14},
        {%Node{color: "white", edges: [10]}, 9, 25},
        {%Node{color: "white", edges: [12]}, 20, 25},
        {%Node{color: "white", edges: [12]}, 7, 28},
        {%Node{color: "white", edges: [12]}, 2, 28},
        {%Node{color: "white", edges: [13]}, 22, 28},
        {%Node{color: "white", edges: []}, 28, 28}
      ],
      3
    }
  end

  def preset(3) do
    nodes =
      for i <- 0..7,
          j <- 0..7 do
        x = j * 4 + 1
        y = i * 4 + 1

        {%Node{color: "white", edges: []}, x, y}
      end

    {
      nodes
      |> Enum.with_index(fn {node, x, y}, index ->
        cond do
          rem(index + 1, 8) == 0 and index < 56 ->
            {%Node{node | edges: [index + 8]}, x, y}

          index == 63 ->
            {node, x, y}

          index < 56 ->
            {%Node{node | edges: [index + 1, index + 8]}, x, y}

          index >= 56 ->
            {%Node{node | edges: [index + 1]}, x, y}

          true ->
            {node, x, y}
        end
      end),
      3
    }
  end

  def preset(4) do
    nodes =
      for i <- 0..14,
          j <- 0..14 do
        x = j * 2 + 1
        y = i * 2 + 1

        {%Node{color: "white", edges: []}, x, y}
      end

    {
      nodes
      |> Enum.with_index(fn {node, x, y}, index ->
        cond do
          rem(index + 1, 15) == 0 and index < 210 ->
            {%Node{node | edges: [index + 15]}, x, y}

          index == 224 ->
            {node, x, y}

          index < 210 ->
            {%Node{node | edges: [index + 1, index + 15]}, x, y}

          index >= 210 ->
            {%Node{node | edges: [index + 1]}, x, y}

          true ->
            {node, x, y}
        end
      end),
      3
    }
  end

  def preset(5) do
    nodes =
      for i <- 0..7,
          j <- 0..7 do
        x = j * 4 + 1
        y = i * 4 + 1

        {%Node{color: "white", edges: []}, x, y}
      end

    {
      nodes
      |> Enum.with_index(fn {node, x, y}, index ->
        cond do
          rem(index + 1, 8) == 0 and index < 56 ->
            {%Node{node | edges: [index + 7, index + 8]}, x, y}

          rem(index, 8) == 0 and index < 56 ->
            {%Node{node | edges: [index + 1, index + 8, index + 9]}, x, y}

          index < 56 ->
            {%Node{node | edges: [index + 1, index + 7, index + 8, index + 9]}, x, y}

          index == 63 ->
            {node, x, y}

          index >= 56 ->
            {%Node{node | edges: [index + 1]}, x, y}

          true ->
            {node, x, y}
        end
      end),
      4
    }
  end

  defp get_ellapsed_time_in_ms(socket) do
    ((System.monotonic_time(:nanosecond) - socket.assigns.start_time) / 1_000_000.0)
    |> Float.round(2)
  end
end
