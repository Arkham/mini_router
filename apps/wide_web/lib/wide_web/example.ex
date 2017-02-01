defmodule WideWeb.Example do
  alias WideWeb.Router

  def build_na do
    na = get_region(:na)

    ~w(atlanta chicago los_angeles dallas denver new_york)a
    |> Enum.each(fn atom ->
      start_router(atom, na)
    end)

    connect(:atlanta, :chicago, na)
    connect(:los_angeles, :new_york, na)
    connect(:chicago, :new_york, na)
    connect(:denver, :dallas, na)
    connect(:denver, :los_angeles, na)

    :ok
  end

  def build_eu do
    eu = get_region(:eu)

    ~w(london rome paris madrid amsterdam frankfurt)a
    |> Enum.each(fn atom ->
      start_router(atom, eu)
    end)

    connect(:london, :madrid, eu)
    connect(:london, :paris, eu)
    connect(:london, :amsterdam, eu)
    connect(:rome, :madrid, eu)
    connect(:rome, :frankfurt, eu)
    connect(:amsterdam, :frankfurt, eu)
    connect(:frankfurt, :madrid, eu)

    :ok
  end

  def connect(first, second, country), do: connect({first, country}, {second, country})
  def connect({first_name, _} = first, {second_name, _} = second) do
    send(first, {:add, second_name, second})
    send(second, {:add, first_name, first})
    IO.puts "Connected #{inspect first} to #{inspect second}"
  end

  def connect_eu_and_na  do
    eu = get_region(:eu)
    na = get_region(:na)

    connect({:london, eu}, {:new_york, na})
    connect({:madrid, eu}, {:los_angeles, na})

    :ok
  end

  def status(name, region_name) do
    send({name, get_region(region_name)}, {:status, self()})
    receive do
      {:status, status} -> status
    after
      5000 -> IO.puts "No status received"
    end
  end

  def build_topology do
    build_eu()
    build_na()
    connect_eu_and_na()
  end

  def send_greeting(first \\ :frankfurt, second \\ :denver, message \\ "Greetings") do
    Node.list
    |> Enum.each(fn(node) ->
      send({first, node}, {:send, second, message})
    end)
  end

  def sync_mass_send(first \\ :frankfurt, second \\ :denver, n \\ 10) do
    (1..n)
    |> Enum.each(fn(index) ->
      send_greeting(first, second, "Greetings from #{first} (#{index})")
      Process.sleep(1000)
    end)
  end

  def async_mass_send(first \\ :frankfurt, second \\ :denver, n \\ 10) do
    (1..n)
    |> Task.async_stream(fn(index) ->
      send_greeting(first, second, "Greetings from #{first} (#{index})")
    end)
    |> Enum.to_list
  end

  defp start_router(name, region) do
    current = self()

    Node.spawn(region, fn ->
      Router.start(name)
      IO.puts "Started #{name} router in #{region}"
      send current, :done
    end)

    receive do
      :done -> :ok
    after
      5000 -> IO.puts "Could not start country #{name} on region #{}"
    end
  end

  defp get_region(name) do
    name = to_string(name)

    Node.list
    |> Enum.map(&to_string/1)
    |> Enum.find(fn s -> String.starts_with?(s, name) end)
    |> String.to_atom
  end
end
