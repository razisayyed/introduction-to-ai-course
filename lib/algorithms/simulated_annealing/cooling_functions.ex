defmodule SimulatedAnnealing.CoolingFunctions do
  @moduledoc """
  This module provides the cooling functions that can be used to cool the system in simulated annealing.

  The cooling functions are used to decrease the temperature of the system as the iteration increases.

  Cooling function are passed as an atom to the `cooling_function` option in the `SimulatedAnnealing.Options` struct.
  """

  def fast_cooling(iteration, opts) do
    opts.initial_temperature / (1 + iteration)
  end

  def blotzmann(iteration, opts) do
    opts.initial_temperature / :math.log(1 + iteration)
  end

  def exponential_cooling(iteration, opts) do
    x = opts.initial_temperature * :math.pow(opts.cooling_rate, iteration)
    IO.inspect(x)
    x
  end
end
