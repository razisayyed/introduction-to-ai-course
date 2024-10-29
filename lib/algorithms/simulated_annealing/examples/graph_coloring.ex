defmodule SimulatedAnnealing.GraphColoring do
  @moduledoc """
  This module defines the problem of graph coloring that can be solved using simulated annealing.

  opts is a Keyword list with the following options:
  :nodes - a list of nodes in the graph. Each node is a map with the following keys:
    - color: the color of the node
    - edges: a list of the neighbors indexes
  :colors_count - the number of colors that can be used to color the nodes
  """

  @behaviour SimulatedAnnealing.Problem

  defmodule Node do
    @moduledoc """
    This module defines the node of the graph.
    """
    defstruct color: nil, edges: []
  end

  @doc """
  Initializes the state of the graph coloring problem.

  The initialization of the state is done by randomly assigning colors to the nodes.
  """
  @impl true
  def initial_state(opts) do
    # return the allowed colors list based on colors_count option. ex: ["green", "blue", "yellow"]
    colors = get_colors(opts)

    Keyword.get(opts, :nodes, [])
    |> Enum.map(fn node ->
      case node do
        nil -> nil
        _ -> %Node{node | color: Enum.random(colors)}
      end
    end)
  end

  @impl true
  def next_state(state, opts \\ []) do
    # return the allowed colors list based on colors_count option. ex: ["green", "blue", "yellow"]
    colors = get_colors(opts)

    # select a random node
    index = get_random_index(state)

    # change the color of the node
    node =
      state
      |> Enum.at(index)
      |> Map.put(:color, Enum.random(colors))

    # replace the node in the state
    state
    |> List.replace_at(index, node)
  end

  defp get_random_index(state) do
    index = Enum.random(0..(length(state) - 1))

    case Enum.at(state, index) do
      nil -> get_random_index(state)
      _ -> index
    end
  end

  @impl true
  def energy(state) do
    state
    |> Enum.reduce(0, fn node, acc ->
      case node do
        nil ->
          acc

        _ ->
          acc +
            Enum.reduce(node.edges, 0, fn edge, acc ->
              neighbor = Enum.at(state, edge, %Node{color: "none", edges: []})

              case node.color == neighbor.color do
                true -> acc + 1
                false -> acc
              end
            end)
      end
    end)
  end

  @doc """
  Terminate the algorithm if the maximum number of iterations is reached or the temperature is below the minimum temperature or the best energy is 0.
  """
  @impl true
  def terminate?(best_energy) do
    best_energy == 0
  end

  defp get_colors(opts) do
    colors_count = Keyword.get(opts, :colors_count, 3)

    # get the colors
    Enum.take(
      [
        "green",
        "blue",
        "yellow",
        "purple",
        "orange",
        "pink",
        "cyan",
        "magenta",
        "lime",
        "olive",
        "maroon",
        "navy",
        "teal",
        "silver",
        "gold",
        "gray",
        "brown",
        "tan",
        "azure",
        "ivory"
      ],
      colors_count
    )
  end
end
