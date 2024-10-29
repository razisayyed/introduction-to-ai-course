defmodule GeneticAlgorithms.Tools.Mutation do
  alias GeneticAlgorithms.Types.Chromosome

  def uniform(chromosome, opts \\ []) do
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.01)
    mutation_rate = if mutation_rate < 0 or mutation_rate > 1, do: 0.01, else: mutation_rate

    Enum.map(chromosome.genes, fn gene ->
      if :rand.uniform() < mutation_rate do
        :rand.uniform(2)
      else
        gene
      end
    end)
  end

  def swap(chromosome, opts \\ []) do
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.01)
    mutation_rate = if mutation_rate < 0 or mutation_rate > 1, do: 0.01, else: mutation_rate

    Enum.reduce(chromosome.genes, {[], nil}, fn gene, {_genes, prev_gene} ->
      if :rand.uniform() < mutation_rate do
        {Enum.reverse([gene, prev_gene]), nil}
      else
        {Enum.reverse([gene, prev_gene]), gene}
      end
    end)
    |> elem(0)
  end

  def inversion(chromosome, _opts \\ []) do
    # mutation_rate = Keyword.get(opts, :mutation_rate, 0.01)
    # mutation_rate = if mutation_rate < 0 or mutation_rate > 1, do: 0.01, else: mutation_rate

    [cx1, cx2] = 0..(chromosome.size - 1) |> Enum.take_random(2) |> Enum.sort()

    {head, mid} = Enum.split(chromosome.genes, cx1)
    {mid, tail} = Enum.split(mid, cx2 - cx1)

    %Chromosome{chromosome | genes: head ++ Enum.reverse(mid) ++ tail}
  end

  def scramble(chromosome, opts \\ []) do
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.01)
    mutation_rate = if mutation_rate < 0 or mutation_rate > 1, do: 0.01, else: mutation_rate

    if :rand.uniform() < mutation_rate do
      Enum.shuffle(chromosome.genes)
    else
      chromosome.genes
    end
  end
end
