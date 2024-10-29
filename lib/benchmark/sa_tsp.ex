defmodule Benchmark.SaTsp do
  alias SimulatedAnnealing.Examples.TSP
  alias SimulatedAnnealing.Options
  alias SimulatedAnnealing.Solver

  @problem_opts [cities_count: 25]

  @opts %Options{
    initial_temperature: 1000,
    cooling_function: :fast_cooling,
    cooling_rate: 0.993,
    max_iterations: 2_000_000_000,
    min_temperature: 0,
    problem_opts: @problem_opts
  }

  def sa_nqueens() do
    IO.puts("Energy\tIteration\tTime")
    # run 100 times
    Enum.reduce(0..19, 0, fn _i, _acc ->
      state =
        Solver.initialize(TSP, %Options{
          problem_opts: @problem_opts
        })

      start_time = System.monotonic_time(:nanosecond)
      {_status, result} = sa_nqueens_iter(:ok, state, start_time, 0)

      IO.puts(
        "#{result.best_energy}\t#{result.iteration}\t#{System.monotonic_time(:nanosecond) - start_time}"
      )
    end)
  end

  def sa_nqueens_iter(status, state, start_time, ellapsed_time)
      when status != :terminate and ellapsed_time < 60_000_000_000 do
    {status, state} =
      Solver.next_state(
        state,
        TSP,
        @opts
      )

    sa_nqueens_iter(status, state, start_time, System.monotonic_time(:nanosecond) - start_time)
  end

  def sa_nqueens_iter(status, state, _start_time, _ellapsed_time) do
    {status, state}
  end
end
