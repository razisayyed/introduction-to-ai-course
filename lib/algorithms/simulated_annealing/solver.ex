defmodule SimulatedAnnealing.Solver do
  @moduledoc """
  This module provides the solver that can be used to solve a problem using simulated annealing.

  The problem to be solved should implement the `SimulatedAnnealing.Problem` behaviour.
  """

  alias SimulatedAnnealing.CoolingFunctions

  defmodule State do
    @moduledoc """
    This module defines the state of the simulated annealing algorithm.
    """

    defstruct current: nil,
              best: nil,
              current_energy: nil,
              best_energy: nil,
              iteration: nil,
              temperature: nil,
              annealing_iteration: nil,
              best_age: nil
  end

  @doc """
  Initializes the state of the simulated annealing algorithm.

  problem is a module that implements the `SimulatedAnnealing.Problem` behaviour.

  opts is a struct of type `SimulatedAnnealing.Options` that contains the options to configure the simulated annealing algorithm.

  ```elixir
  %Options{
    initial_temperature: 10.0,
    cooling_function: :fast_cooling,
    cooling_rate: 0.993,
    max_iterations: 10000,
    min_temperature: 0,
    reannealing_max: 0,
    problem_opts: []
  }
  ```

  problem_opts is a list of options that can be passed to the problem.
  It depends on the problem being solved.
  """
  def initialize(problem, opts) do
    initial_state = problem.initial_state(opts.problem_opts)

    energy = problem.energy(initial_state)

    %State{
      current: initial_state,
      best: initial_state,
      current_energy: energy,
      best_energy: energy,
      iteration: 0,
      annealing_iteration: 0,
      best_age: 0,
      temperature: opts.initial_temperature
    }
  end

  @doc """
  Returns the next state of the problem based on the current state if the algorithm should continue. Otherwise, it returns `{:terminate, state}`.

  This function depends on pattern matching to determine the next state of the problem based on the current state.
  (Please see the next defp next_state/5 for the pattern matching logic.)

  returns `{:ok, state}` if there is a new state to be processed.
  returns `{:terminate, state}` if the algorithm should terminate.
  """

  def next_state(state, _problem, opts)
      when (opts.max_iterations > 0 and state.iteration >= opts.max_iterations) or
             state.temperature <= opts.min_temperature do
    {:terminate, state}
  end

  def next_state(state, problem, opts) do
    case problem.terminate?(state.best_energy) do
      true ->
        {:terminate, state}

      false ->
        # Update iteration and annealing_iteration
        state = %{
          state
          | iteration: state.iteration + 1,
            best_age:
              case opts.max_reannealing_iterations do
                m when m < state.best_age -> 0
                _ -> state.best_age + 1
              end,
            annealing_iteration:
              case opts.max_reannealing_iterations do
                0 -> state.annealing_iteration + 1
                m when m < state.best_age -> 0
                _ -> state.annealing_iteration + 1
              end
        }

        # Get the neighbour state and its energy
        neighbour = problem.next_state(state.current, opts.problem_opts)
        neighbour_energy = problem.energy(neighbour)

        # Get the temperature for the current iteration
        temperature = get_temperature(state.annealing_iteration + 1, opts)

        # Calculate the energy difference between the current state and the neighbour state
        delta_e =
          case state.current_energy - neighbour_energy do
            delta when delta > 0 -> delta * -1
            delta -> delta
          end

        # Check if the neighbour state should be accepted
        rollete =
          try do
            Math.pow(Math.e(), delta_e / temperature) > :rand.uniform()
          rescue
            _ -> false
          end

        {:ok, next_state(state, neighbour, neighbour_energy, temperature, rollete)}
    end
  end

  defp next_state(state, neighbour, neighbour_energy, temperature, _rollete)
       when neighbour_energy < state.best_energy do
    %State{
      state
      | current: neighbour,
        current_energy: neighbour_energy,
        best: neighbour,
        best_energy: neighbour_energy,
        best_age: 0,
        temperature: temperature
    }
  end

  defp next_state(state, neighbour, neighbour_energy, temperature, _rollete)
       when neighbour_energy == state.best_energy do
    %State{
      state
      | current: neighbour,
        current_energy: neighbour_energy,
        best: neighbour,
        best_energy: neighbour_energy,
        temperature: temperature
    }
  end

  defp next_state(state, neighbour, neighbour_energy, temperature, rollete)
       when neighbour_energy <= state.current_energy or rollete do
    %State{
      state
      | current: neighbour,
        current_energy: neighbour_energy,
        temperature: temperature
    }
  end

  defp next_state(state, _neighbour, neighbour_energy, temperature, rollete)
       when neighbour_energy > state.current_energy and not rollete do
    %State{
      state
      | temperature: temperature
    }
  end

  @doc """
  Runs the simulated annealing algorithm until the termination condition is met.

  The algorithm will return {:terminate, state}. Where state contains the best solution found.
  """

  def run(problem, opts) do
    initialize(problem, opts)
    |> solve(problem, opts)
  end

  defp get_temperature(iteration, opts) do
    case opts.cooling_function do
      :fast_cooling -> CoolingFunctions.fast_cooling(iteration, opts)
      :blotzmann -> CoolingFunctions.blotzmann(iteration, opts)
      :exponential_cooling -> CoolingFunctions.exponential_cooling(iteration, opts)
    end
  end

  defp solve(state, problem, opts) do
    case next_state(state, problem, opts) do
      {:ok, state} ->
        solve(state, problem, opts)

      {:terminate, result} ->
        result
    end
  end
end
