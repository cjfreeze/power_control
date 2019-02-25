# PowerControl

PowerControl is a library for start-up and runtime configuration of embedded device power consumption settings. This can be used to decrease power usage of embedded devices or increase their performance. For more information, see the benchmarks section.

[![Hex](https://img.shields.io/hexpm/v/power_control.svg?style=flat)](https://hexdocs.pm/power_control/PowerControl.html)

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

## What governors can I use?

Governors are dependant on hardware, and while it's possible to guess what governors you have access to based on your device, the best way to be sure is to run `PowerControl.list_cpu_governors()` in your nerves iex shell (on the device you want to identify) to see a list of atoms representing your device's supported governors. For a more detailed walkthough, check out the [docs](https://hexdocs.pm/power_control/PowerControl.html).

## Benchmarks

Lets take a look at the following fibonacci benchmark run on a Raspberry Pi Zero W using different [`CPUFreq`](https://www.kernel.org/doc/html/v4.15/admin-guide/pm/cpufreq.html) settings:

```
iex(1)> PowerControl.cpu_info(:cpu0).speed
700000
iex(2)> PowerTest.bench_fib(145862)
"11611628 μs"
iex(3)> PowerControl.set_cpu_governor(:cpu0, :performance)
{:ok, :performance}
iex(4)> PowerControl.cpu_info(:cpu0).speed
1000000
iex(5)> PowerTest.bench_fib(145862)
"8332247 μs"
```

Just by changing the CPU governor at runtime to `:performance`, we see a significant increase in benchmark speed. If you compare the ratios of the two benchmarks to the ratios of the clock speeds, you can see they are almost the same (Benchmark: 0.71, CPU clock: 0.7).
