defmodule Benchmark.GANQueens do
  alias GeneticAlgorithms.Solver
  alias GeneticAlgorithms.Examples.NQueens

  @max_generations 1_000_000_000
  @population_size 80
  @board_size 80

  @problem_opts [
    board_size: @board_size,
    max_generations: @max_generations
  ]

  @opts [
    population_size: @population_size,
    selection_rate: 0.8,
    mutation_rate: 0.2,
    crossover_type: :pmx,
    selection_type: :roulette_wheel,
    problem_opts: @problem_opts
  ]

  def ga_nqueens() do
    IO.puts("Energy\tIteration\tTime")
    # run 100 times
    Enum.reduce(0..19, 0, fn _i, _acc ->
      population =
        Solver.init(NQueens, @opts)

      start_time = System.monotonic_time(:nanosecond)

      {_status, _population, generation, best} =
        ga_nqueens_iter(:ok, population, 0, nil, start_time, 0)

      IO.puts(
        "#{best.fitness}\t#{generation}\t#{System.monotonic_time(:nanosecond) - start_time}"
      )
    end)
  end

  def ga_nqueens_iter(status, population, generation, best, start_time, ellapsed_time)
      when status != :terminate and ellapsed_time < 25_000_000_000 do
    {status, population, best, generation} =
      Solver.next_generation(
        population,
        NQueens,
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
