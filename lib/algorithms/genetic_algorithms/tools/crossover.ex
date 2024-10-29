defmodule GeneticAlgorithms.Tools.Crossover do
  alias GeneticAlgorithms.Types.Chromosome

  def single_point(p1, p2) do
    # (p1.size - 2) to make sure the point is not at the end
    # :rand.uniform will not return zero, so we don't need to add 1
    cx_point = :rand.uniform(p1.size - 2)
    {p1_head, p1_tail} = Enum.split(p1.genes, cx_point)
    {p2_head, p2_tail} = Enum.split(p2.genes, cx_point)
    {c1, c2} = {p1_head ++ p2_tail, p2_head ++ p1_tail}

    {%Chromosome{genes: c1, size: length(c1)}, %Chromosome{genes: c2, size: length(c2)}}
  end

  def two_point(p1, p2) do
    # (p1.size - 2) to make sure the point is not at the end
    [cx1, cx2] = 1..(p1.size - 2) |> Enum.take_random(2) |> Enum.sort()
    {p1_head, p1_mid} = Enum.split(p1.genes, cx1)
    {p1_mid, p1_tail} = Enum.split(p1_mid, cx2 - cx1)
    {p2_head, p2_mid} = Enum.split(p2.genes, cx1)
    {p2_mid, p2_tail} = Enum.split(p2_mid, cx2 - cx1)
    {c1, c2} = {p1_head ++ p2_mid ++ p1_tail, p2_head ++ p1_mid ++ p2_tail}

    {%Chromosome{genes: c1, size: length(c1)}, %Chromosome{genes: c2, size: length(c2)}}
  end

  def uniform(p1, p2) do
    {c1, c2} =
      Enum.reduce(Enum.zip(p1.genes, p2.genes), {[], []}, fn {g1, g2}, {c1, c2} ->
        if :rand.uniform() < 0.5 do
          {[g1 | c1], [g2 | c2]}
        else
          {[g2 | c1], [g1 | c2]}
        end
      end)

    {%Chromosome{genes: c1, size: length(c1)}, %Chromosome{genes: c2, size: length(c2)}}
  end

  def pmx(p1, p2) do
    # Randomly select two crossover points
    # [cx1, cx2] = 0..(p1.size - 1) |> Enum.take_random(2) |> Enum.sort()
    # this is the same as the line above but faster.
    cx1 = Enum.random(0..(p1.size - 1))
    cx2 = Enum.random((cx1 + 1)..(p1.size - 1))

    {p1_head, p1_mid} = Enum.split(p1.genes, cx1)
    {p1_mid, p1_tail} = Enum.split(p1_mid, cx2 - cx1)
    {p2_head, p2_mid} = Enum.split(p2.genes, cx1)
    {p2_mid, p2_tail} = Enum.split(p2_mid, cx2 - cx1)
    # Create the initial offspring with the selected segments

    map1 = fill_map(p2_mid, p1_mid)
    map2 = fill_map(p1_mid, p2_mid)

    c1 = fill_offspring(p1_head, map1) ++ p2_mid ++ fill_offspring(p1_tail, map1)
    c2 = fill_offspring(p2_head, map2) ++ p1_mid ++ fill_offspring(p2_tail, map2)

    {%Chromosome{genes: c1, size: length(c1)}, %Chromosome{genes: c2, size: length(c2)}}
  end

  def fill_map(mid1, mid2) do
    Enum.reduce(0..length(mid1), Map.new(), fn i, map ->
      gene1 = Enum.at(mid1, i)
      gene2 = Enum.at(mid2, i)

      if gene1 == gene2 do
        map
      else
        Map.put(map, gene1, gene2)
      end
    end)
  end

  def fill_offspring(genes, map) do
    Enum.reduce(0..(length(genes) - 1), genes, fn i, genes ->
      fill_offspring(genes, map, i)
      # if Map.has_key?(map, Enum.at(genes, i)) do
      #   List.replace_at(genes, i, Map.get(map, Enum.at(genes, i)))
      # else
      #   genes
      # end
    end)
  end

  def fill_offspring(genes, map, i) do
    if Map.has_key?(map, Enum.at(genes, i)) do
      List.replace_at(genes, i, Map.get(map, Enum.at(genes, i)))
      |> fill_offspring(map, i)
    else
      genes
    end
  end
end
