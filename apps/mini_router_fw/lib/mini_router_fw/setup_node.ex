defmodule MiniRouterFw.SetupNode do
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
        set_hostname(hostname)
        set_cookie()
        connect_to_master()
      :no ->
        Logger.info("No network found, retrying...")
    end

    Process.send_after(self(), :check_for_network, @retry_interval)
    {:noreply, state}
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

  defp set_hostname(hostname) do
    case node() do
      :"nonode@nohost" ->
        Logger.info("Network found, enabling distributed mode for #{hostname}")
        Node.start(hostname)
      _other -> :ok
    end
  end

  defp set_cookie do
    Node.set_cookie(get_cookie())
  end

  defp connect_to_master do
    Node.connect(get_master())
  end

  defp get_settings do
    Application.get_env(:mini_router_fw, :node)
  end

  defp get_name do
    get_settings()
    |> Keyword.fetch!(:hostname)
  end

  defp get_cookie do
    get_settings()
    |> Keyword.fetch!(:cookie)
  end

  defp get_master do
    get_settings()
    |> Keyword.fetch!(:master)
  end
end
