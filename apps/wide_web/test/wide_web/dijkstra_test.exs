defmodule WideWeb.DijkstraTest do
  use ExUnit.Case
  alias WideWeb.Dijkstra, as: WWDijkstra
  alias WideWeb.Map, as: WWMap

  test "entry returns the length of the shortest path to the node" do
    assert WWDijkstra.entry([{:berlin, 2, :paris}], :berlin) == 2
  end

  test "entry returns 0 if node isn't found" do
    assert WWDijkstra.entry([{:berlin, 2, :paris}], :london) == 0
  end

  test "replace replaces the entry for a given node" do
    list = [{:berlin, 2, :paris}]

    assert WWDijkstra.replace(list, :berlin, 4, :london) ==
      [{:berlin, 4, :london}]
  end

  test "replace changes the list only if the node already exists" do
    list = [{:berlin, 2, :paris}]

    assert WWDijkstra.replace(list, :rome, 4, :paris) ==
      [{:berlin, 2, :paris}]
  end

  test "replace keeps the list sorted by hops count" do
    list = [{:berlin, 2, :paris}, {:rome, 3, :madrid}]

    assert WWDijkstra.replace(list, :berlin, 4, :london) ==
      [{:rome, 3, :madrid}, {:berlin, 4, :london}]
  end

  test "update changes the list only if we are improving the path" do
    list =
      [{:berlin, 2, :paris}, {:rome, 3, :madrid}]
      |> WWDijkstra.update(:berlin, 1, :amsterdam)
      |> WWDijkstra.update(:rome, 4, :budapest)

    assert WWDijkstra.entry(list, :berlin) == 1
    assert WWDijkstra.entry(list, :rome) == 3
  end

  test "update changes the list only if the node exists" do
    list =
      [{:berlin, 2, :paris}, {:rome, 3, :madrid}]
      |> WWDijkstra.update(:moscow, 10, :paris)

    assert WWDijkstra.entry(list, :moscow) == 0
  end

  test "iterate updates a routing table iterating over a sorted_list and a map" do
    list = [{:paris, 0, :paris}, {:amsterdam, :infinity, :unknown}, {:berlin, :infinity, :unknown}]
    map = WWMap.new(%{paris: [:berlin], berlin: [:amsterdam]})

    assert WWDijkstra.iterate(%{}, list, map) == %{paris: :paris, amsterdam: :paris, berlin: :paris}
  end

  test "table constructs a routing table given a list of gateways and a map" do
    gateways = [:madrid, :paris]
    map = WWMap.new(%{madrid: [:berlin], paris: [:rome, :madrid]})

    assert WWDijkstra.table(gateways, map) ==
      %{berlin: :madrid, rome: :paris, madrid: :madrid, paris: :paris}
  end

  test "route searches the routing table for a gateway to a destination" do
    routing_table = %{berlin: :madrid}

    assert WWDijkstra.route(routing_table, :berlin) == {:ok, :madrid}
    assert WWDijkstra.route(routing_table, :london) == :not_found
  end
end
