defmodule AICourseWeb.AiCourseComponents do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS

  attr :solution, :list, required: true
  attr :square_size, :integer, default: 50

  def nqueens_board(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={"0 0 #{@square_size * length(@solution)} #{@square_size * length(@solution)}"}
      class="w-full rounded-lg"
    >
      <%= for row <- 0..(length(@solution) -1) do %>
        <%= for col <- 0..(length(@solution) -1) do %>
          <% x = col * @square_size %>
          <% y = row * @square_size %>
          <% color = if rem(row + col, 2) == 0, do: "#f0d9b5", else: "#b58863" %>
          <rect x={x} y={y} width={@square_size} height={@square_size} fill={color} />
          <%= if Enum.at(@solution, col) == row do %>
            <text
              x={x + @square_size / 2}
              y={y + @square_size / 1.3}
              font-size="50"
              text-anchor="middle"
              fill="#374151"
            >
              ♛
            </text>
          <% end %>
        <% end %>
      <% end %>
    </svg>
    """
  end

  attr :cities, :list, required: true

  def tsp_map(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24500 62500" class="w-full rounded-lg">
      <%= for i <- 0..(length(@cities) - 1) do %>
        <% city1 = Enum.at(@cities, i) %>
        <% city2 = Enum.at(@cities, rem(i + 1, length(@cities))) %>
        <circle
          cx={longitude_to_x(city1.longitude)}
          cy={latitude_to_y(city1.latitude)}
          r="400"
          fill="#ff000077"
          stroke-width="150"
          stroke="#000000"
        />
        <line
          x1={longitude_to_x(city1.longitude)}
          y1={latitude_to_y(city1.latitude)}
          x2={longitude_to_x(city2.longitude)}
          y2={latitude_to_y(city2.latitude)}
          stroke="#000000"
          stroke-width="200"
        />
      <% end %>
    </svg>
    """
  end

  defp latitude_to_y(latitude) do
    # Convert latitude to y of range 0 to 62500 and relative to a map starts with latitude 33.37
    (33.52 - latitude) * (62500 / (33.52 - 29.34))
  end

  defp longitude_to_x(longitude) do
    # Convert longitude to x of range 0 to 24500 and relative to a map starts with longitude 34.01
    (longitude - 34.05) * (24500 / (35.63 - 34.05))
  end

  attr :size, :integer, default: 31
  attr :nodes, :list, required: true
  attr :selected_node, :integer, default: nil

  def coloring_graph(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox={"0 0 #{50 * @size} #{50 * @size}"} class="w-full">
      <%= for {node, x1, y1} <- Enum.filter(@nodes, fn {node, _, _} -> node != nil end) do %>
        <%= for edge <- node.edges do %>
          <% {neighbor, x2, y2} = Enum.at(@nodes, edge) %>
          <line
            x1={25 + 50 * x1}
            y1={25 + 50 * y1}
            x2={25 + 50 * x2}
            y2={25 + 50 * y2}
            stroke={
              if node.color != "white" and node.color == neighbor.color, do: "red", else: "black"
            }
            stroke-width={if node.color != "white" and node.color == neighbor.color, do: 10, else: 5}
          />
        <% end %>
      <% end %>
      <%= for {{node, x, y},idx} <- Enum.with_index(@nodes) |> Enum.filter(fn {{node, _, _}, _} -> node != nil end) do %>
        <%= if idx == @selected_node do %>
          <circle
            cx={25 + 50 * x}
            cy={25 + 50 * y}
            r="40"
            fill={node.color}
            stroke="black"
            stroke-width="5"
          />
        <% else %>
          <circle
            cx={25 + 50 * x}
            cy={25 + 50 * y}
            r="25"
            fill={node.color}
            stroke="black"
            stroke-width="5"
          />
        <% end %>
      <% end %>
    </svg>
    """
  end
end
