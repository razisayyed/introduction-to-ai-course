defmodule GeneticAlgorithms.Problem do
  @moduledoc """
  This module defines the problem that the genetic algorithm will solve.
  """

  alias GeneticAlgorithms.Types.Chromosome

  @type t() :: module()

  @doc """
  This function generates a random chromosome.
  """
  @callback genotype(Keyword.t()) :: Chromosome.t()

  @doc """
  This function calculates the fitness of a chromosome.
  """
  @callback fitness_function(Chromosome.t()) :: number()

  @doc """
  This function sorts the population by fitness.
  """
  @callback fitness_sorter() :: fun

  @doc """
  This function checks if the chromosome is a solution.
  """
  @callback terminate?(Enum.t(), integer(), opts: Keyword.t()) :: boolean()

  @doc """
  This function repairs the chromosome if it is not valid after crossover.
  """
  @callback repair_chromosome(Chromosome.t()) :: Chromosome.t()

  @doc """
  This function mutates the chromosome.
  """
  @callback mutate(Chromosome.t(), opts: Keyword.t()) :: Chromosome.t()
end
