defmodule SimulatedAnnealing.SimpleExample do
  @behaviour SimulatedAnnealing.Problem

  @impl true
  def initial_state(_opts) do
    0..7 |> Enum.shuffle()
  end

  @impl true
  def next_state(state, _opts \\ []) do
    index1 = 0..7 |> Enum.random()
    index2 = get_random_index(index1)

    state
    |> List.replace_at(index1, Enum.at(state, index2))
    |> List.replace_at(index2, Enum.at(state, index1))
  end

  @impl true
  def energy(state) do
    state
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(0, fn [h1, h2], acc ->
      acc +
        if h1 + 1 == h2 do
          0
        else
          1
        end
    end)
  end

  @impl true
  def terminate?(best_energy) do
    best_energy == 0
  end

  defp get_random_index(index) do
    index2 = 0..7 |> Enum.random()

    if index2 == index do
      get_random_index(index)
    else
      index2
    end
  end
end
