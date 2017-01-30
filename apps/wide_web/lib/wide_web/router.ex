defmodule WideWeb.Router do
  alias WideWeb.{InterfaceSet, Map, Dijkstra, History}

  @broadcast_interval 10_000

  defmodule State do
    defstruct name: nil, n: nil, history: nil, interfaces: nil,
      table: nil, map: nil
  end

  def start(name) do
    Process.register(spawn(fn -> init(name) end), name)
  end

  def stop(node) do
    send(node, :stop)
    Process.unregister(node)
  end

  def init(name) do
    interfaces = InterfaceSet.new()
    map = Map.new()
    table = Dijkstra.table([name], map)
    history = History.new(name)

    send(self(), :broadcast)

    router(%State{name: name,
                  n: 0,
                  history: history,
                  interfaces: interfaces,
                  table: table,
                  map: map})
  end

  def router(%State{name: name,
                    n: n,
                    history: history,
                    interfaces: interfaces,
                    table: table,
                    map: map} = state) do
    receive do
      {:add, node, pid} ->
        ref = Process.monitor(pid)
        new_interfaces = InterfaceSet.add(interfaces, node, ref, pid)
        send(self(), :update)
        router(%State{state | interfaces: new_interfaces})

      {:remove, node} ->
        {:ok, ref} = InterfaceSet.ref(interfaces, node)
        Process.demonitor(ref)
        new_interfaces = InterfaceSet.remove(interfaces, node)
        send(self(), :update)
        router(%State{state | interfaces: new_interfaces})

      {:DOWN, ref, :process, _, _} ->
        case InterfaceSet.name(interfaces, ref) do
          {:ok, down} ->
            log(name, "exit received from #{down}")
            new_interfaces = InterfaceSet.remove(interfaces, down)
            send(self(), :update)
            router(%State{state | interfaces: new_interfaces})
          :not_found ->
            router(state)
        end

      {:status, from} ->
        send(from, {:status, state})
        router(state)

      {:links, node, version, links} ->
        case History.check(history, node, version) do
          {:new, new_history} ->
            if version < 5 do
              log(name, "received new links (v#{version}) from node #{node}")
            end
            InterfaceSet.broadcast(interfaces, {:links, node, version, links})
            new_map = Map.update(map, node, links)
            send(self(), :update)
            router(%State{state | history: new_history, map: new_map})

          :old ->
            router(state)
        end

      :update ->
         new_table = Dijkstra.table([name|InterfaceSet.list(interfaces)], map)
         router(%State{state | table: new_table})

      :broadcast ->
        InterfaceSet.broadcast(interfaces,
                               {:links, name, n+1, InterfaceSet.list(interfaces)})
        Process.send_after(self(), :broadcast, @broadcast_interval)
        router(%State{state | n: n+1})

      {:route, ^name, _from, message} ->
        log(name, "received message #{inspect(message)}")
        router(state)

      {:route, to, from, message} ->
        log(name, "routing message #{inspect(message)}")
        case Dijkstra.route(table, to) do
          {:ok, gateway} ->
            log(name, "using gateway #{gateway}")
            case InterfaceSet.lookup(interfaces, gateway) do
              {:ok, pid} ->
                send(pid, {:route, to, from, message})
              :not_found ->
                :ok
            end

          :not_found ->
            log(name, "gateway not found, aborting")
            :ok
        end
        router(state)

      {:send, to, message} ->
        send(self(), {:route, to, name, message})
        router(state)

      :stop ->
        :ok
    end
  end

  defp log(name, message) do
    name = "[#{name}]" |> String.pad_trailing(15)
    IO.puts("#{name} #{message}")
  end
end
