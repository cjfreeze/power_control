# PowerControl

PowerControl is a library for start-up and runtime configuration of embedded device power consumption settings. This can be used to decrease power usage of embedded devices or increase their performance. For more information, see the benchmarks section.

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
