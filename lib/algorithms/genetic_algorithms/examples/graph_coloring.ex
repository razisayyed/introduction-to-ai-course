defmodule GeneticAlgorithms.Examples.GraphColoring do
  @behaviour GeneticAlgorithms.Problem
  alias GeneticAlgorithms.Types.Chromosome

  defmodule Node do
    @moduledoc """
    This module defines the node of the graph.
    """
    defstruct color: nil, edges: []
  end

  @impl true
  def genotype(opts) do
    colors = get_colors(opts)

    nodes =
      Keyword.get(opts, :nodes, [])
      |> Enum.map(fn node ->
        case node do
          nil -> nil
          _ -> %Node{node | color: Enum.random(colors)}
        end
      end)

    %Chromosome{genes: nodes, size: length(nodes)}
  end

  @impl true
  def fitness_function(chromosome) do
    chromosome.genes
    |> Enum.reduce(0, fn node, acc ->
      case node do
        nil ->
          acc

        _ ->
          acc +
            Enum.reduce(node.edges, 0, fn edge, acc ->
              neighbor = Enum.at(chromosome.genes, edge, %Node{color: "none", edges: []})

              case node.color == neighbor.color do
                true -> acc + 1
                false -> acc
              end
            end)
      end
    end)
  end

  @impl true
  def fitness_sorter() do
    &<=/2
  end

  @impl true
  def terminate?(population, generation, opts) do
    max_generations = Keyword.get(opts, :max_generations, 1000)
    hd(population).fitness == 0 or generation >= max_generations
  end

  @impl true
  def repair_chromosome(chromosome) do
    chromosome
    # %Chromosome{
    #   chromosome
    #   | genes: Enum.uniq(chromosome.genes ++ Enum.to_list(0..(chromosome.size - 1)))
    # }
  end

  @impl true
  def mutate(chromosome, opts) do
    # return the allowed colors list based on colors_count option. ex: ["green", "blue", "yellow"]
    colors = get_colors(opts)

    index = Enum.random(0..(chromosome.size - 1))

    # change the color of the node
    node =
      chromosome.genes
      |> Enum.at(index)
      |> Map.put(:color, Enum.random(colors))

    # replace the node in the state
    genes =
      chromosome.genes
      |> List.replace_at(index, node)

    %Chromosome{
      chromosome
      | genes: genes,
        mutations_count: chromosome.mutations_count + 1
    }
  end

  @square_size 50

  def board_as_svg(queens_positions) do
    board_size = length(queens_positions)

    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{@square_size * board_size} #{@square_size * board_size}" class="w-full rounded-lg">
      #{generate_board(queens_positions)}
    </svg>
    """
  end

  defp generate_board(queens_positions) do
    Enum.map_join(0..(length(queens_positions) - 1), "\n", fn row ->
      Enum.map_join(0..(length(queens_positions) - 1), "\n", fn col ->
        x = col * @square_size
        y = row * @square_size
        # alternating colors for chessboard squares
        color = if rem(row + col, 2) == 0, do: "#f0d9b5", else: "#b58863"

        rect = """
        <rect x="#{x}" y="#{y}" width="#{@square_size}" height="#{@square_size}" fill="#{color}"/>
        """

        # Add a "Q" where the queen is placed
        text =
          if Enum.at(queens_positions, col) == row do
            """
            <text x="#{x + @square_size / 2}" y="#{y + @square_size / 1.3}" font-size="50" text-anchor="middle" fill="#374151">♛</text>
            """
          else
            ""
          end

        rect <> text
      end)
    end)
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
