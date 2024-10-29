defmodule GeneticAlgorithms.Examples.NQueens do
  @behaviour GeneticAlgorithms.Problem
  alias GeneticAlgorithms.Types.Chromosome

  @impl true
  def genotype(opts) do
    board_size = Keyword.get(opts, :board_size, 8)
    genes = Enum.shuffle(0..(board_size - 1))
    %Chromosome{genes: genes, size: board_size}
  end

  @impl true
  def fitness_function(chromosome) do
    Enum.reduce(0..(chromosome.size - 1), 0, fn col1, acc ->
      row1 = Enum.at(chromosome.genes, col1)

      acc +
        Enum.count(Enum.with_index(chromosome.genes), fn {row2, col2} ->
          col1 != col2 and
            (row1 == row2 or abs(row1 - row2) == abs(col1 - col2))
        end)
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

    # board_size = Enum.at(population, 0).size
    # max_generations = Keyword.get(opts, :max_generations, 1000)

    # Enum.max_by(population, &fitness_function/1).fitness == board_size or
    #   generation >= max_generations
  end

  @impl true
  def repair_chromosome(chromosome) do
    %Chromosome{
      chromosome
      | genes: Enum.uniq(chromosome.genes ++ Enum.to_list(0..(chromosome.size - 1)))
    }
  end

  @impl true
  def mutate(chromosome, _opts) do
    i1 = Enum.random(0..(chromosome.size - 1))
    i2 = Enum.random(0..(chromosome.size - 1))
    e1 = Enum.at(chromosome.genes, i1)
    e2 = Enum.at(chromosome.genes, i2)

    genes =
      chromosome.genes
      |> List.replace_at(i1, e2)
      |> List.replace_at(i2, e1)

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
end
