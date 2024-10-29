defmodule GeneticAlgorithms.Examples.TSP do
  @behaviour GeneticAlgorithms.Problem
  alias GeneticAlgorithms.Types.Chromosome

  defmodule City do
    defstruct [:name, :latitude, :longitude]
  end

  defp cities_map do
    [
      %City{name: "Safad", latitude: 32.9675, longitude: 35.5015},
      %City{name: "Acre", latitude: 32.9226, longitude: 35.0687},
      %City{name: "Tiberias", latitude: 32.7936, longitude: 35.5328},
      %City{name: "Nazareth", latitude: 32.7036, longitude: 35.2956},
      %City{name: "Haifa", latitude: 32.7940, longitude: 34.9896},
      %City{name: "Baysan", latitude: 32.5036, longitude: 35.4997},
      %City{name: "Jenin", latitude: 32.4603, longitude: 35.3036},
      %City{name: "Tulkarm", latitude: 32.3167, longitude: 35.0167},
      %City{name: "Nablus", latitude: 32.2211, longitude: 35.2544},
      %City{name: "Jaffa", latitude: 32.0667, longitude: 34.7667},
      %City{name: "Ramallah", latitude: 31.9038, longitude: 35.2034},
      %City{name: "Allyd", latitude: 31.5186, longitude: 34.5950},
      %City{name: "Juerusalem", latitude: 31.7683, longitude: 35.2137},
      %City{name: "Hebron", latitude: 31.5293, longitude: 35.0996},
      %City{name: "Gaza", latitude: 31.5000, longitude: 34.4667},
      %City{name: "Beer Alsabe'", latitude: 31.2518, longitude: 34.7915},
      %City{name: "Jericho", latitude: 31.8667, longitude: 35.4500},
      %City{name: "Qalqilya", latitude: 32.1956, longitude: 34.9939},
      %City{name: "Tubas", latitude: 32.3194, longitude: 35.3686},
      %City{name: "Salfit", latitude: 32.0856, longitude: 35.1711},
      %City{name: "Khan Yunis", latitude: 31.3400, longitude: 34.3100},
      %City{name: "Rafah", latitude: 31.2833, longitude: 34.2500},
      %City{name: "Askalan", latitude: 31.6693, longitude: 34.5715},
      %City{name: "Asdood", latitude: 31.8167, longitude: 34.6500},
      %City{name: "Eilat", latitude: 29.5581, longitude: 34.9482}
    ]
  end

  @impl true
  def genotype(opts) do
    cities_count = Keyword.get(opts, :cities_count, 10)
    # Generate a random list of cities coordinates
    cities = cities_map() |> Enum.take(cities_count) |> Enum.shuffle()

    %Chromosome{genes: cities, size: cities_count}
  end

  @impl true
  def fitness_function(chromosome) do
    # Calculate the total distance of the path
    Enum.reduce(0..(chromosome.size - 1), 0, fn i, acc ->
      %City{latitude: x1, longitude: y1} = Enum.at(chromosome.genes, i)
      %City{latitude: x2, longitude: y2} = Enum.at(chromosome.genes, rem(i + 1, chromosome.size))
      # acc + acos(sin(lat1)*sin(lat2)+cos(lat1)*cos(lat2)*cos(lon2-lon1))*6371
      # acc +
      #   :math.acos(
      #     :math.sin(x1) * :math.sin(x2) + :math.cos(x1) * :math.cos(x2) * :math.cos(y2 - y1)
      #   ) * 6371

      # ACOS( SIN(lat1*PI()/180)*SIN(lat2*PI()/180) + COS(lat1*PI()/180)*COS(lat2*PI()/180)*COS(lon2*PI()/180-lon1*PI()/180) ) * 6371000
      acc +
        :math.acos(
          :math.sin(x1 * :math.pi() / 180) * :math.sin(x2 * :math.pi() / 180) +
            :math.cos(x1 * :math.pi() / 180) * :math.cos(x2 * :math.pi() / 180) *
              :math.cos((y2 - y1) * :math.pi() / 180)
        ) * 6_371
    end)
  end

  @impl true
  def fitness_sorter() do
    &<=/2
  end

  @impl true
  def terminate?(_population, generation, opts) do
    max_generations = Keyword.get(opts, :max_generations, 1000)
    generation >= max_generations
  end

  @impl true
  def repair_chromosome(chromosome) do
    genes = Enum.uniq_by(chromosome.genes, fn %City{name: name} -> name end)
    cities = Enum.take(cities_map(), chromosome.size) |> Enum.shuffle()

    genes = Enum.uniq_by(genes ++ cities, & &1.name)

    %Chromosome{chromosome | genes: genes}
  end

  def print_path(solution) do
    Enum.each(solution.genes, fn %City{latitude: latitude, longitude: longitude} ->
      IO.puts("latitude : #{latitude}, longitude : #{longitude}")
    end)
  end

  def board_as_svg(chromosome) do
    # svg_size = chromosome.size

    # cities_map

    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24500 62500" class="w-full rounded-lg">
      #{generate_board(chromosome)}
    </svg>
    """
  end

  @impl true
  def mutate(chromosome, _opts) do
    i1 = Enum.random(0..(chromosome.size - 1))
    i2 = Enum.random(0..(chromosome.size - 1))
    e1 = Enum.at(chromosome.genes, i1)
    e2 = Enum.at(chromosome.genes, i2)

    genes =
      chromosome.genes
      |> List.replace_at(i1, e2)
      |> List.replace_at(i2, e1)

    %Chromosome{
      chromosome
      | genes: genes,
        mutations_count: chromosome.mutations_count + 1
    }
  end

  defp generate_board(chromosome) do
    # draw circle for each city and line between them, and add a line from the last city to the first one.

    Enum.map_join(chromosome.genes, "\n", fn _gene ->
      Enum.map_join(0..(chromosome.size - 1), "\n", fn i ->
        %City{latitude: latitude1, longitude: longitude1} = Enum.at(chromosome.genes, i)

        %City{latitude: latitude2, longitude: longitude2} =
          Enum.at(chromosome.genes, rem(i + 1, chromosome.size))

        circle = """
        <circle cx="#{longitude_to_x(longitude1)}" cy="#{latitude_to_y(latitude1)}" r="500" fill="#ff0000aa" stroke-width="50" stroke="#00000033" />
        """

        line = """
        <line x1="#{longitude_to_x(longitude1)}" y1="#{latitude_to_y(latitude1)}" x2="#{longitude_to_x(longitude2)}" y2="#{latitude_to_y(latitude2)}" stroke="#00000033" stroke-width="100" />
        """

        circle <> line
      end)
    end)
  end

  def latitude_to_y(latitude) do
    # Convert latitude to y of range 0 to 62500 and relative to a map starts with latitude 33.37
    (33.52 - latitude) * (62500 / (33.52 - 29.34))
  end

  def longitude_to_x(longitude) do
    # Convert longitude to x of range 0 to 24500 and relative to a map starts with longitude 34.01
    (longitude - 34.05) * (24500 / (35.63 - 34.05))
  end
end
