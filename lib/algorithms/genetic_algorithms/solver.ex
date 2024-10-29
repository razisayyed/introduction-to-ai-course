defmodule GeneticAlgorithms.Solver do
  alias GeneticAlgorithms.Types.Chromosome
  alias GeneticAlgorithms.Tools

  defp initialize(problem, opts) do
    population_size = Keyword.get(opts, :population_size, 100)
    problem_opts = Keyword.get(opts, :problem_opts, [])

    # IO.inspect(opts)
    # IO.inspect(population_size)
    # IO.inspect(problem_opts)

    population = for _ <- 1..population_size, do: problem.genotype(problem_opts)
    evaluate(population, &problem.fitness_function/1, &problem.fitness_sorter/0, opts)
  end

  def evaluate(population, fitness_function, fitness_sorter, _opts \\ []) do
    # # multi-threading
    population
    |> Enum.chunk_every(ceil(length(population) / 8))
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        Enum.map(chunk, fn chromosome ->
          %Chromosome{
            chromosome
            | fitness: fitness_function.(chromosome),
              age: chromosome.age + 1
          }
        end)
      end)
    end)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
    # |> Enum.zip(population)
    # |> Enum.map(fn {fitness, chromosome} -> %Chromosome{chromosome | fitness: fitness} end)
    |> Enum.sort_by(fitness_function, fitness_sorter.())

    # population
    # |> Enum.map(fn chromosome ->
    #   fitness = fitness_function.(chromosome)
    #   age = chromosome.age + 1
    #   %Chromosome{chromosome | fitness: fitness, age: age}
    # end)
    # |> Enum.sort_by(fitness_function, fitness_sorter.())
  end

  def select(population, _problem, opts \\ []) do
    select_fn =
      case Keyword.get(opts, :selection_type, :steady_state) do
        :steady_state -> &Tools.Selection.steady_state/2
        :roulette_wheel -> &Tools.Selection.roulette_wheel/2
        :tournament -> &Tools.Selection.tournament/2
      end

    select_rate = Keyword.get(opts, :selection_rate, 0.5)
    n = round(length(population) * select_rate)
    n = if rem(n, 2) == 0, do: n, else: n + 1

    parents =
      select_fn
      |> apply([population, n])

    leftover = MapSet.difference(MapSet.new(population), MapSet.new(parents))

    parents =
      parents
      |> Enum.chunk_every(2)
      |> Enum.map(&List.to_tuple(&1))

    {parents, MapSet.to_list(leftover)}
  end

  def crossover(population, problem, opts \\ []) do
    crossover_fn =
      case Keyword.get(opts, :crossover_type, :single_point) do
        :single_point -> &Tools.Crossover.single_point/2
        :two_point -> &Tools.Crossover.two_point/2
        :uniform -> &Tools.Crossover.uniform/2
        :pmx -> &Tools.Crossover.pmx/2
      end

    population
    |> Enum.chunk_every(ceil(length(population) / 8))
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        Enum.reduce(
          chunk,
          [],
          fn {p1, p2}, acc ->
            # Prevent the same parents from producing the same children
            # if p1.genes == p2.genes do
            #   IO.inspect("#{p1.genes}, #{p2.genes}")
            #   acc
            # else
            crossovers_count = max(p1.crossovers_count, p2.crossovers_count) + 1
            mutations_count = max(p1.mutations_count, p2.mutations_count)
            {c1, c2} = apply(crossover_fn, [p1, p2])

            c1 = %Chromosome{
              c1
              | crossovers_count: crossovers_count,
                mutations_count: mutations_count
            }

            c2 = %Chromosome{
              c2
              | crossovers_count: crossovers_count,
                mutations_count: mutations_count
            }

            [c1, c2 | acc]
            # end
          end
        )
        |> Enum.map(&problem.repair_chromosome/1)
      end)
    end)
    |> Enum.map(&Task.await/1)
    |> List.flatten()

    # population
    # |> Enum.reduce(
    #   [],
    #   fn {p1, p2}, acc ->
    #     crossovers_count = max(p1.crossovers_count, p2.crossovers_count) + 1
    #     {c1, c2} = apply(crossover_fn, [p1, p2])
    #     c1 = %Chromosome{c1 | crossovers_count: crossovers_count}
    #     c2 = %Chromosome{c2 | crossovers_count: crossovers_count}
    #     [c1, c2 | acc]
    #   end
    # )
    # |> Enum.map(&problem.repair_chromosome/1)
  end

  def mutation(population, problem, opts \\ []) do
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.05)

    # genes =
    #   Enum.reduce(population, [], fn chromosome, acc ->
    #     acc ++ chromosome.genes
    #   end)

    # n = round(length(genes) * mutation_rate)

    # 0..n |> Enum.each(fn _ ->
    #   i = Enum.random(0..(length(genes) - 1))
    #   genes = genes |> List.replace_at(i, :rand.uniform(2))
    # end)
    problem_opts = Keyword.get(opts, :problem_opts, [])

    population
    |> Enum.chunk_every(ceil(length(population) / 8))
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        Enum.map(chunk, fn chromosome ->
          if :rand.uniform() < mutation_rate do
            problem.mutate(chromosome, problem_opts)
          else
            chromosome
          end
        end)
      end)
    end)
    |> Enum.map(&Task.await/1)
    |> List.flatten()

    # population
    # |> Enum.map(fn chromosome ->
    #   if :rand.uniform() < mutation_rate do
    #     i1 = Enum.random(0..(chromosome.size - 1))
    #     i2 = Enum.random(0..(chromosome.size - 1))
    #     e1 = Enum.at(chromosome.genes, i1)
    #     e2 = Enum.at(chromosome.genes, i2)

    #     genes =
    #       chromosome.genes
    #       |> List.replace_at(i1, e2)
    #       |> List.replace_at(i2, e1)

    #     %Chromosome{chromosome | genes: genes, mutations_count: chromosome.mutations_count + 1}
    #     # %Chromosome{chromosome | genes: Enum.shuffle(chromosome.genes)}
    #   else
    #     chromosome
    #   end
    # end)
  end

  def init(problem, opts \\ []) do
    initialize(problem, opts)
  end

  def run(problem, opts \\ []) do
    population = initialize(problem, opts)

    population
    |> evolve(problem, 1, opts)
  end

  def evolve(population, problem, generation, opts \\ []) do
    case next_generation(population, problem, generation, nil, opts) do
      {:ok, population, _best, generation} ->
        evolve(population, problem, generation, opts)

      result ->
        result
    end
  end

  def next_generation(population, problem, generation, current_best, opts \\ []) do
    # population =
    #   evaluate(population, &problem.fitness_function/1, &problem.fitness_sorter/0, opts)

    best = hd(population)

    current_best_is_better =
      current_best != nil and
        apply(problem.fitness_sorter(), [current_best.fitness, best.fitness])

    best = if current_best_is_better, do: current_best, else: best
    # best =
    #   case current_best do
    #     nil -> best
    #     _ -> if best.fitness >= current_best.fitness, do: best, else: current_best
    #   end

    problem_opts = Keyword.get(opts, :problem_opts, [])

    case problem.terminate?(population, generation, problem_opts) do
      true ->
        {:terminate, population, best, generation}

      false ->
        {parents, _leftover} = population |> select(problem, opts)

        children = Enum.shuffle(parents) |> crossover(problem, opts)

        population = (population |> Enum.take(length(population) - length(children))) ++ children

        # <-
        population =
          population
          |> mutation(problem, opts)
          |> evaluate(&problem.fitness_function/1, &problem.fitness_sorter/0, opts)

        # |> mutation(problem, opts)

        {:ok, population, best, generation + 1}

        # {:ok, population, best, generation + 1}
    end
  end
end
