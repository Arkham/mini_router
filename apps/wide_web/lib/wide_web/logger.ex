defmodule WideWeb.Logger do
  def start do
    Process.register(spawn(&init/0), :logger)
  end

  def init do
    loop()
  end

  def loop do
    receive do
      {:log, name, message} ->
        name = "[#{name}]" |> String.pad_trailing(15)
        IO.puts("#{name} #{message}")

      other ->
        IO.puts "Received unknown message #{inspect other}"
    end

    loop()
  end
end
