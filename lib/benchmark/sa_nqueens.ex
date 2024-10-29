defmodule Benchmark.SANQueens do
  alias SimulatedAnnealing.Options
  alias SimulatedAnnealing.Solver
  alias SimulatedAnnealing.Examples.NQueens

  @problem_opts [board_size: 80]

  @opts %Options{
    initial_temperature: 3.0,
    cooling_function: :blotzmann,
    cooling_rate: 0.993,
    max_iterations: 1_000_000,
    min_temperature: 0,
    problem_opts: @problem_opts
  }

  def sa_nqueens() do
    IO.puts("Energy\tIteration\tTime")
    # run 100 times
    Enum.reduce(0..19, 0, fn _i, _acc ->
      state =
        Solver.initialize(NQueens, %Options{
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
      when status != :terminate and ellapsed_time < 1_000_000_000_000 do
    {status, state} =
      Solver.next_state(
        state,
        NQueens,
        @opts
      )

    sa_nqueens_iter(status, state, start_time, System.monotonic_time(:nanosecond) - start_time)
  end

  def sa_nqueens_iter(status, state, _start_time, _ellapsed_time) do
    {status, state}
  end
end
