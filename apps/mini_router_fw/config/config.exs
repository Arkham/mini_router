# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"

config :nerves, :firmware,
  rootfs_additions: "rootfs-additions"

config :mini_router_fw, :wlan0,
  ssid: System.get_env("MINI_ROUTER_WLAN_SSID"),
  psk: System.get_env("MINI_ROUTER_WLAN_PSK"),
  key_mgmt: :"WPA-PSK"

config :mini_router_fw, :networking,
  hostname: System.get_env("MINI_ROUTER_HOSTNAME") |> String.to_atom,
  cookie: System.get_env("MINI_ROUTER_COOKIE") |> String.to_atom,
  master: System.get_env("MINI_ROUTER_MASTER") |> String.to_atom
