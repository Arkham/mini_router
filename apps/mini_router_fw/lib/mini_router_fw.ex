defmodule MiniRouterFw do
  use Application

  @interface :wlan0
  @kernel_modules Mix.Project.config[:kernel_modules] || []

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Task, [&start_empd/0], restart: :transient, id: Nerves.Init.Empd),
      worker(Task, [&init_kernel_modules/0], restart: :transient, id: Nerves.Init.KernelModules),
      worker(Task, [&init_network/0], restart: :transient, id: Nerves.Init.Network),
      worker(MiniRouterFw.SetupHostname, [])
    ]

    opts = [strategy: :one_for_one, name: MiniRouterFw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_empd do
    System.cmd("/usr/lib/erlang/bin/epmd", ["-daemon"])
  end

  defp init_kernel_modules do
    Enum.each(@kernel_modules, &(System.cmd("modprobe", [&1])))
  end

  defp init_network do
    opts = Application.get_env(:mini_router_fw, @interface)
    Nerves.InterimWiFi.setup(@interface, opts)
  end
end
