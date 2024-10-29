defmodule SimulatedAnnealing.Problem do
  @moduledoc """
  This module defines the behaviour of a problem that can be solved using simulated annealing.
  """

  @callback initial_state(Keyword.t()) :: any()
  @callback next_state(any(), any()) :: any()
  @callback energy(any()) :: number()
  @callback terminate?(any()) :: boolean()
end
