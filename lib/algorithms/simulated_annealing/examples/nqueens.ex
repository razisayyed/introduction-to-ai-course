defmodule SimulatedAnnealing.Examples.NQueens do
  @behaviour SimulatedAnnealing.Problem

  @impl true
  def initial_state(opts) do
    board_size = Keyword.get(opts, :board_size, 8)
    state = Enum.shuffle(0..(board_size - 1))
    state
  end

  @impl true
  def next_state(state, _opts \\ []) do
    i1 = Enum.random(0..(length(state) - 1))
    i2 = Enum.random(0..(length(state) - 1))
    e1 = Enum.at(state, i1)
    e2 = Enum.at(state, i2)

    state
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end

  @impl true
  def energy(state) do
    Enum.reduce(0..(length(state) - 1), 0, fn col1, acc ->
      row1 = Enum.at(state, col1)

      acc +
        Enum.count(Enum.with_index(state), fn {row2, col2} ->
          col1 != col2 and
            (row1 == row2 or abs(row1 - row2) == abs(col1 - col2))
        end)
    end)
  end

  @impl true
  def terminate?(best_energy) do
    best_energy == 0
  end
end
