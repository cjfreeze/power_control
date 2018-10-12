# PowerControl

PowerControl is a library for start-up and runtime configuration of embedded device power consumption settings.

## Installation

Add `power_control` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:power_control, "~> 0.1.0"}
  ]
end
```

If using `shoehorn`, add `:power_control` to your shoehorn apps in your `config.exs`:

```elixir
config :shoehorn,
  init: [:nerves_runtime, ..., :power_control],
  ...
```
It must come after `:nerves_runtime` but has no requirements other than that.

Once installed, startup configuration can be set in your `config.exs` like so:

```elixir
config :power_control,
  cpu_governor: :powersave,
  disable_hdmi: true,
  disable_leds: true
```

