defmodule WideWeb.Map do
  defstruct data: %{}

  def new, do: %__MODULE__{}
  def new(data), do: %__MODULE__{data: data}

  def update(%__MODULE__{data: data} = map, node, links) do
    %__MODULE__{map | data: Map.put(data, node, links)}
  end

  def reachable(%__MODULE__{data: data}, node) do
    Map.get(data, node, [])
  end

  def all_nodes(%__MODULE__{data: data}) do
    data
    |> Enum.reduce(MapSet.new, fn({node, links}, acc) ->
      acc
      |> MapSet.put(node)
      |> MapSet.union(MapSet.new(links))
    end)
    |> MapSet.to_list
  end
end
