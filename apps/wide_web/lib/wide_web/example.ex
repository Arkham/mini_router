defmodule WideWeb.Example do
  alias WideWeb.Router

  def build_sweden do
    sweden = get_sweden()

    ~w(stockholm goteborg malmo lund)a
    |> Enum.each(fn atom ->
      start_country(atom, sweden)
    end)

    connect(:stockholm, :goteborg, sweden)
    connect(:stockholm, :malmo, sweden)
    connect(:malmo, :lund, sweden)
  end

  def build_italy do
    italy = get_italy()

    ~w(rome milan turin)a
    |> Enum.each(fn atom ->
      start_country(atom, italy)
    end)

    connect(:rome, :milan, italy)
    connect(:milan, :turin, italy)
  end

  def connect(first, second, country), do: connect({first, country}, {second, country})
  def connect({first_name, _} = first, {second_name, _} = second) do
    send(first, {:add, second_name, second})
    send(second, {:add, first_name, first})
  end

  def connect_sweden_and_italy  do
    connect({:stockholm, get_sweden()}, {:rome, get_italy()})
    connect({:goteborg, get_sweden()}, {:milan, get_italy()})
  end

  def send_greeting do
    send({:malmo, get_sweden()}, {:send, :turin, "Hej fran Sveridge"})
  end

  def status(node) do
    send(node, {:status, self()})
    receive do
      {:status, status} -> status
    end
  end

  defp start_country(name, node) do
    Node.spawn(node, fn ->
      Router.start(name)
    end)
  end

  defp get_sweden do
    find_node_called("sweden")
  end

  defp get_italy do
    find_node_called("italy")
  end

  defp find_node_called(name) do
    Node.list
    |> Enum.map(&to_string/1)
    |> Enum.find(fn s -> String.starts_with?(s, name) end)
    |> String.to_atom
  end
end
