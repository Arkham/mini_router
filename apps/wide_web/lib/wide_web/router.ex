defmodule WideWeb.Router do
  alias WideWeb.{InterfaceSet, Map, Dijkstra, History}

  @broadcast_interval 3_000
  @default_ttl 20

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

    Process.send_after(self(), :broadcast, @broadcast_interval)

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
      # Interface management
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
            log(name, %{type: :node_down, node: down})
            new_interfaces = InterfaceSet.remove(interfaces, down)
            send(self(), :update)
            router(%State{state | interfaces: new_interfaces})
          :not_found ->
            router(state)
        end

      # Incoming link-state message
      {:links, node, version, links} ->
        case History.check(history, node, version) do
          {:new, new_history} ->
            log(name, %{type: :links, version: version, source: node})
            InterfaceSet.broadcast(interfaces, {:links, node, version, links})
            new_map = Map.update(map, node, links)
            send(self(), :update)
            router(%State{state | history: new_history, map: new_map})

          :old ->
            router(state)
        end

      # Update routing table
      :update ->
         new_table = Dijkstra.table([name|InterfaceSet.list(interfaces)], map)
         router(%State{state | table: new_table})

      # Broadcast new version of link-state message
      :broadcast ->
        InterfaceSet.broadcast(interfaces, {:links, name, n+1, InterfaceSet.list(interfaces)})
        Process.send_after(self(), :broadcast, @broadcast_interval)
        router(%State{state | n: n+1})

      # Route a message
      {:route, ^name, from, message, _ttl} ->
        log(name, %{type: :received, from: from, message: message})
        router(state)

      {:route, to, from, message, ttl} when ttl <= 0 ->
        log(name, %{type: :error, reason: :ttl_expired, message: message, from: from, to: to})
        router(state)

      {:route, to, from, message, ttl} ->
        case Dijkstra.route(table, to) do
          {:ok, gateway} ->
            case InterfaceSet.lookup(interfaces, gateway) do
              {:ok, pid} ->
                log(name, %{type: :routing, message: message, from: from, to: to, gateway: gateway, ttl: ttl})
                send(pid, {:route, to, from, message, ttl - 1})
              :not_found ->
                log(name, %{type: :error, reason: :no_interface, message: message,
                            from: from, to: to, gateway: gateway})
                :ok
            end

          :not_found ->
            log(name, %{type: :error, reason: :no_gateway, message: message,
                        from: from, to: to})
            :ok
        end
        router(state)

      {:send, to, message} ->
        send(self(), {:route, to, name, message, @default_ttl})
        router(state)

      # Debug
      {:status, from} ->
        send(from, {:status, state})
        router(state)

      :stop ->
        :ok
    end
  end

  defp log(name, message) do
    send(get_logger(), {:log, name, message})
  end

  defp get_logger do
    master = Application.get_env(:wide_web, :node)
             |> Keyword.fetch!(:master)

    {:logger, master}
  end
end
