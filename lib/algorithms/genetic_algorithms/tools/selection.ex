defmodule GeneticAlgorithms.Tools.Selection do
  alias GeneticAlgorithms.Types.Chromosome

  def steady_state(population, n) do
    population
    |> Enum.take(n)
  end

  def tournament(population, n) do
    population = Enum.shuffle(population)

    Enum.reduce(0..(n - 1), [], fn i, acc ->
      p1 = Enum.at(population, i * 2)
      p2 = Enum.at(population, i * 2 + 1)
      if p1.fitness > p2.fitness, do: [p1 | acc], else: [p2 | acc]
    end)
  end

  def rank(population, _n) do
    # give each individual a rank based on their rank

    size = length(population)

    population
    |> Enum.with_index()
    |> Enum.filter(fn {_, index} ->
      if index / size < :rand.uniform() do
        true
      else
        false
      end
    end)
  end

  # def roulette_wheel(population, n) do
  #   total_fitness = Enum.reduce(population, 0, fn chromosome, acc -> acc + chromosome.fitness end)

  #   Enum.reduce_while(1..n, [], fn _, acc ->
  #     pick = :rand.uniform() * total_fitness

  #     selected =
  #       Enum.reduce_while(population, 0, fn chromosome, sum ->
  #         sum = sum + chromosome.fitness
  #         if sum >= pick, do: {:halt, chromosome}, else: {:cont, sum}
  #       end)

  #     {:cont, [selected | acc]}
  #   end)
  # end

  def roulette_wheel(population, n) do
    # Extract fitness values from the population

    # Sort the population in ascending order of fitness
    # population = Enum.reverse(population)

    # total_fitness =
    #   Enum.reduce(population, 0, fn %Chromosome{fitness: fitness}, acc -> acc + 1 / fitness end)

    fitness_values =
      Enum.map(population, fn %Chromosome{fitness: fitness} -> 1 / fitness end)

    # fitness_values =
    #   Enum.map(population, fn %Chromosome{fitness: fitness} -> fitness end)

    # Compute the cumulative sum of fitness values
    cumulative_sums = compute_cumulative_sums(fitness_values)
    total_fitness = List.last(cumulative_sums)

    # Perform 'n' selections
    1..n
    |> Enum.chunk_every(ceil(n / 8))
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        Enum.map(chunk, fn _ ->
          rand_val = :rand.uniform() * total_fitness
          select_individual(cumulative_sums, rand_val, population)
        end)
      end)
    end)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
  end

  defp compute_cumulative_sums(fitness_values) do
    fitness_values
    |> Enum.scan(&(&1 + &2))
  end

  defp select_individual(cumulative_sums, rand_val, population) do
    # Find the index where cumulative sum is greater than rand_val
    index =
      Enum.find_index(cumulative_sums, fn cumulative_sum ->
        cumulative_sum >= rand_val
      end)

    # IO.inspect("#{List.last(cumulative_sums)} #{rand_val} #{index}")
    # Return the individual at the selected index
    Enum.at(population, index)
  end
end
