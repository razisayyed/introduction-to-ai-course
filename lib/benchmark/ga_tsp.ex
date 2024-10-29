defmodule Benchmark.GaTsp do
  alias GeneticAlgorithms.Examples.TSP
  alias GeneticAlgorithms.Solver

  @max_generations 1_000_000
  @population_size 8000
  @cities_count 25

  @problem_opts [
    cities_count: @cities_count,
    max_generations: @max_generations
  ]

  @opts [
    population_size: @population_size,
    selection_rate: 0.5,
    mutation_rate: 0.1,
    crossover_type: :pmx,
    selection_type: :roulette_wheel,
    problem_opts: @problem_opts
  ]

  def ga_nqueens() do
    IO.puts("Energy\tIteration\tTime")
    # run 100 times
    Enum.reduce(0..19, 0, fn _i, _acc ->
      population =
        Solver.init(TSP, @opts)

      start_time = System.monotonic_time(:nanosecond)

      {_status, _population, generation, best} =
        ga_nqueens_iter(:ok, population, 0, nil, start_time, 0)

      IO.puts(
        "#{best.fitness}\t#{generation}\t#{System.monotonic_time(:nanosecond) - start_time}"
      )
    end)
  end

  def ga_nqueens_iter(status, population, generation, best, start_time, ellapsed_time)
      when status != :terminate and ellapsed_time < 60_000_000_000 do
    {status, population, best, generation} =
      Solver.next_generation(
        population,
        TSP,
        generation,
        best,
        @opts
      )

    ga_nqueens_iter(
      status,
      population,
      generation,
      best,
      start_time,
      System.monotonic_time(:nanosecond) - start_time
    )
  end

  def ga_nqueens_iter(status, population, generation, best, _start_time, _ellapsed_time) do
    {status, population, generation, best}
  end
end
