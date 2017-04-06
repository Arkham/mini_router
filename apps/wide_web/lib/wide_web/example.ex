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

  def build_asia do
    asia = get_region(:asia)

    ~w(peking tokyo jakarta dubai hong_kong singapore)a
    |> Enum.each(fn atom ->
      start_router(atom, asia)
    end)

    connect(:peking, :tokyo, asia)
    connect(:peking, :jakarta, asia)
    connect(:peking, :dubai, asia)
    connect(:peking, :singapore, asia)
    connect(:tokyo, :singapore, asia)
    connect(:tokyo, :hong_kong, asia)
    connect(:singapore, :jakarta, asia)
    connect(:singapore, :dubai, asia)
    connect(:singapore, :hong_kong, asia)

    :ok
  end


  def connect(first, second, region) do
    connect({first, region}, {second, region})
  end
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

  def connect_eu_and_asia do
    eu = get_region(:eu)
    asia = get_region(:asia)

    connect({:london, eu}, {:singapore, asia})
    connect({:rome, eu}, {:peking, asia})

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

  def test_resilience do
    eu = get_region(:eu)
    na = get_region(:na)

    spawn(fn ->
      sync_mass_send(:frankfurt, :denver, 15)
    end)

    Process.sleep(5_000)

    send({:madrid, eu}, :stop)

    Process.sleep(5_000)

    start_router(:madrid, eu)
    connect({:madrid, eu}, {:los_angeles, na})
    connect(:london, :madrid, eu)
    connect(:rome, :madrid, eu)
    connect(:frankfurt, :madrid, eu)
  end

  def test_global_resilience do
    eu = get_region(:eu)
    na = get_region(:na)

    threads = [
      {:frankfurt, :denver, 20},
      {:rome, :los_angeles, 20},
      {:jakarta, :new_york, 20},
      {:singapore, :dallas, 20}
    ]

    threads
    |> Enum.with_index
    |> Enum.each(fn({{src, dest, n}, sleep}) ->
      Process.sleep(sleep * 100)
      spawn(fn ->
        sync_mass_send(src, dest, n)
      end)
    end)

    Process.sleep(5_000)

    send({:madrid, eu}, :stop)

    Process.sleep(5_000)

    start_router(:madrid, eu)
    connect({:madrid, eu}, {:los_angeles, na})
    connect(:london, :madrid, eu)
    connect(:rome, :madrid, eu)
    connect(:frankfurt, :madrid, eu)
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

  def get_region(name) do
    name = to_string(name)

    Node.list
    |> Enum.map(&to_string/1)
    |> Enum.find(fn s -> String.starts_with?(s, name) end)
    |> String.to_atom
  end
end
