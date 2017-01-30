defmodule WideWeb.MapTest do
  use ExUnit.Case
  doctest WideWeb.Map
  alias WideWeb.Map, as: WWMap

  test "new returns a new map" do
    assert WWMap.new() == %WWMap{}
  end

  test "new accepts a map as argument" do
    assert WWMap.new(%{berlin: [:london]}) ==
      %WWMap{data: %{berlin: [:london]}}
  end

  test "reachable returns a list of connected nodes" do
    map = WWMap.new(%{berlin: [:london, :paris]})
    assert WWMap.reachable(map, :berlin) == [:london, :paris]
    assert WWMap.reachable(map, :london) == []
  end

  test "update saves that a node is connected to other nodes" do
    map = WWMap.new()
    new = WWMap.update(map, :berlin, [:london, :paris])
    assert WWMap.reachable(new, :berlin) == [:london, :paris]
  end

  test "updates replaces previous list of connected nodes" do
    map = WWMap.new(%{berlin: [:london, :paris]})
    new = WWMap.update(map, :berlin, [:rome])
    assert WWMap.reachable(new, :berlin) == [:rome]
  end

  test "all_nodes returns a list of all nodes in map" do
    map = WWMap.new(%{berlin: [:london, :paris]})
    assert WWMap.all_nodes(map) == [:berlin, :london, :paris]
  end
end
