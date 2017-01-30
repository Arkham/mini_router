defmodule WideWeb.Dijkstra do
  def entry(sorted_list, node) do
    {_, hops_count, _} =
      List.keyfind(sorted_list, node, 0, {:unknown, 0, :unknown})

    hops_count
  end

  def replace(sorted_list, dest, hops_count, gateway) do
    case List.keydelete(sorted_list, dest, 0) do
      ^sorted_list -> sorted_list
      new_list -> insert(new_list, dest, hops_count, gateway)
    end
  end

  def insert(sorted_list, dest, hops_count, gateway) do
    [{dest, hops_count, gateway}|sorted_list]
    |> List.keysort(1)
  end

  def update(sorted_list, dest, hops_count, gateway) do
    current_hops_count = entry(sorted_list, dest)

    case hops_count < current_hops_count do
      true ->
        replace(sorted_list, dest, hops_count, gateway)
      false ->
        sorted_list
    end
  end

  def iterate(routing_table, [], _map), do: routing_table
  def iterate(routing_table, [{_, :infinity, _}|_rest], _map), do: routing_table
  def iterate(routing_table, [{dest, hops_count, gateway}|sorted_list], map) do
    new_list = map
               |> WideWeb.Map.reachable(dest)
               |> Enum.reduce(sorted_list, fn(node, acc) ->
                 update(acc, node, hops_count+1, gateway)
               end)

    iterate(Map.put(routing_table, dest, gateway), new_list, map)
  end

  def table(gateways, map) do
    sorted_list = map
                  |> WideWeb.Map.all_nodes
                  |> Enum.map(fn(node) ->
                    case node in gateways do
                      true  -> {node, 0, node}
                      false -> {node, :infinity, :unknown}
                    end
                  end)
                  |> List.keysort(1)

    iterate(%{}, sorted_list, map)
  end

  def route(routing_table, node) do
    case Map.fetch(routing_table, node) do
      {:ok, gateway} -> {:ok, gateway}
      :error         -> :not_found
    end
  end
end
