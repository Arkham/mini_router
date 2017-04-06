defmodule MiniRouterFw.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi3"

  def project do
    [app: :mini_router_fw,
     version: "0.1.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.3"],

     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     kernel_modules: kernel_modules(@target),

     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system(@target)]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {MiniRouterFw, []},
     applications: [:logger, :nerves_interim_wifi, :wide_web]]
  end

  def deps do
    [{:nerves, "~> 0.4.0"},
     {:nerves_interim_wifi, "~> 0.1.1"},
     {:wide_web, in_umbrella: true}]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end

  def kernel_modules("rpi3") do
    ["brcmfmac"]
  end
  def kernel_modules(_), do: []

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end
end
