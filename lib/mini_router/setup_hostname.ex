defmodule MiniRouter.SetupHostname do
  use GenServer
  require Logger

  @retry_interval 5000

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    send(self(), :check_for_network)
    {:ok, nil}
  end

  def handle_info(:check_for_network, state) do
    case is_connected_to_wifi() do
      {:yes, ip} ->
        hostname = "#{get_name()}@#{ip}" |> String.to_atom
        Logger.info("Network found, enabling distributed mode for #{hostname}")

        Node.start(hostname)
        Node.set_cookie(get_cookie())
        Node.connect(get_master())

        {:noreply, state}
      :no ->
        Logger.info("No network found, retrying...")
        Process.send_after(self(), :check_for_network, @retry_interval)
        {:noreply, state}
    end
  end

  defp is_connected_to_wifi do
    {:ok, [first_interface|_]} = :inet.getif()

    case first_interface do
      {{127, 0, 0, 1}, _, _} ->
        :no
      {ip, _, _} ->
        {:yes, :inet_parse.ntoa(ip)}
    end
  end

  defp get_settings do
    Application.get_env(:mini_router, :networking)
  end

  defp get_name do
    get_settings()[:hostname]
  end

  defp get_cookie do
    get_settings()[:cookie]
  end

  defp get_master do
    get_settings()[:master]
  end
end
