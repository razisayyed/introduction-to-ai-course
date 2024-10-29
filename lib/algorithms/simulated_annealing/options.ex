defmodule SimulatedAnnealing do
  @moduledoc """
  This module provides the options that is used to configure the simulated annealing algorithm.
  """

  defmodule Options do
    defstruct initial_temperature: 10.0,
              cooling_function: :fast_cooling,
              cooling_rate: 0.995,
              max_iterations: 10000,
              max_reannealing_iterations: 0,
              min_temperature: 0,
              problem_opts: []
  end
end
