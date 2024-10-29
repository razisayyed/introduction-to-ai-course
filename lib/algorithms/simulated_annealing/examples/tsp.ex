defmodule SimulatedAnnealing.Examples.TSP do
  @behaviour SimulatedAnnealing.Problem

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
  def initial_state(opts) do
    cities_count = Keyword.get(opts, :cities_count, 10)
    cities = Enum.take(cities_map(), cities_count) |> Enum.shuffle()

    cities
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
    # Calculate the total distance of the path
    Enum.reduce(0..(length(state) - 1), 0, fn i, acc ->
      %City{latitude: x1, longitude: y1} = Enum.at(state, i)
      %City{latitude: x2, longitude: y2} = Enum.at(state, rem(i + 1, length(state)))

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
  def terminate?(_best_energy) do
    false
  end
end
