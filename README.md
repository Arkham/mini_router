# MiniRouter

A small scale replica of an Internet router, written in Elixir and deployable to
a Raspberry Pi 3.

## Installation

1. `cp .envrc.example .envrc` and set the correct environment variables.
2. `cd apps/mini_router_fw`
3. `mix deps.get && mix firmware`
4. Insert your SD card and run `mix firmware.burn`
