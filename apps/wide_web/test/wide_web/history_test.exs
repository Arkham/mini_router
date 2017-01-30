defmodule WideWeb.HistoryTest do
  use ExUnit.Case
  alias WideWeb.History, as: WWHistory

  test "check checks that message with a certain count from node is old or new" do
    history = WWHistory.new(:root)

    assert {:new, history} = WWHistory.check(history, :alice, 1)
    assert WWHistory.check(history, :alice, 1) == :old
    assert WWHistory.check(history, :alice, 0) == :old
    assert {:new, _} = WWHistory.check(history, :alice, 2)
  end

  test "check always returns :old for messages belonging to root node" do
    history = WWHistory.new(:root)

    assert WWHistory.check(history, :root, 10) == :old
  end
end
