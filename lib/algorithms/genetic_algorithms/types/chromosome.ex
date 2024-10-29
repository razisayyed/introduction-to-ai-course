defmodule GeneticAlgorithms.Types.Chromosome do
  @moduledoc """
  This module defines the chromosome type.
  """
  @type t :: %__MODULE__{
          # The genes of the chromosome.
          genes: Enum.t(),
          # The size of the chromosome.
          size: integer(),
          # The fitness of the chromosome (will be calculated by the fitness function).
          fitness: number(),
          # The age of the chromosome. It will be incremented by 1 every generation.
          age: integer(),
          # The number of mutations happened to the chromosome. (will be incremented by 1 every mutation).
          # This is useful for debugging purposes.
          mutations_count: integer(),
          # The number of crossovers happened to produce the chromosome. (max(parent1.crossover, parent2.crossover) will be incremented by 1 every crossover).
          # This is useful for debugging purposes.
          crossovers_count: integer()
        }

  # The genes and size of the chromosome must be provided.
  @enforce_keys [:genes, :size]

  defstruct [:genes, size: 0, fitness: 0, age: 0, mutations_count: 0, crossovers_count: 0]
end
