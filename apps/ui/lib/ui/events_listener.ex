defmodule Ui.EventsListener do
  @message_types [:links, :routing, :received, :error, :node_down]

  def start do
    Process.register(spawn(&init/0), :logger)
  end

  def hide_links do
    send(:logger, {:set_whitelist, @message_types |> List.delete(:links)})
  end

  def init do
    loop(@message_types)
  end

  def loop(whitelist) do
    receive do
      {:log, name, %{type: :routing} = message} ->
        Ui.Endpoint.broadcast!("room:lobby", "routing_event", Map.put(message, :current, name))

      {:log, name, %{type: type} = message} ->
        if type in whitelist do
          name = "[#{name}]" |> String.pad_trailing(15)
          type = "<#{type}>" |> String.pad_trailing(10)
          message = Map.delete(message, :type)
          IO.puts("#{name} #{type} #{inspect message}")
        end

      {:set_whitelist, types} ->
        loop(types)

      other ->
        IO.puts "Received unknown message #{inspect other}"
    end

    loop(whitelist)
  end
end
