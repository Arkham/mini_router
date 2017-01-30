defmodule WideWeb.InterfaceSetTest do
  use ExUnit.Case
  alias WideWeb.InterfaceSet, as: WWSet

  test "new returns a new interface set" do
    assert WWSet.new() == %WWSet{}
  end

  test "add associates a ref to a pid" do
    set = WWSet.new()
          |> WWSet.add(:london, make_ref(), self())

    assert WWSet.lookup(set, :london) == {:ok, self()}
  end

  test "remove disassociates the given name" do
    set = WWSet.new()
          |> WWSet.add(:london, make_ref(), self())
          |> WWSet.remove(:london)

    assert WWSet.lookup(set, :london) == :not_found
  end

  test "ref returns the reference associated to a name" do
    ref = make_ref()
    set = WWSet.new()
          |> WWSet.add(:london, ref, self())

    assert WWSet.ref(set, :london) == {:ok, ref}
  end

  test "name returns the name associated to a reference" do
    ref = make_ref()
    set = WWSet.new()
          |> WWSet.add(:london, ref, self())

    assert WWSet.name(set, ref) == {:ok, :london}
  end

  test "list returns the list with all names" do
    set = WWSet.new()
          |> WWSet.add(:london, make_ref(), self())
          |> WWSet.add(:paris, make_ref(), self())

    assert WWSet.list(set) == [:london, :paris]
  end

  test "broadcast sends a certain message to all interface processes" do
    set = WWSet.new()
          |> WWSet.add(:london, make_ref(), self())

    WWSet.broadcast(set, :hello_world)

    assert_received :hello_world
  end
end
