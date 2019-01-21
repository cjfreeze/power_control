defmodule PowerControl do
  @moduledoc """
  `PowerControl` is a library that enables runtime configuration of embedded linux for power conservation or performance via native elixir.
  """
  alias PowerControl.{CPU, LED, HDMI}

  def shoehorn_spec do
    {__MODULE__, :init, []}
  end

  @doc false
  def init do
    with :ok <- CPU.startup(),
         :ok <- HDMI.startup(),
         :ok <- LED.startup() do
      :ok
    else
    _ -> :error
    end
  end

  @doc """
  Lists system CPUS.

  ```
  iex> list_cpus()
  [:cpu0]
  ```
  """
  def list_cpus(name \\ CPU) do
    GenServer.call(name, :list_cpus)
  end

  @doc """
  Returns an info map for a CPU.

  ```
  iex> cpu_info(:cpu0)
  %{max_speed: 1000000, min_speed: 700000, speed: 1000000}
  ```
  """
  def cpu_info(name \\ CPU, cpu) do
    GenServer.call(name, {:cpu_stats, cpu})
  end

  @doc """
  Returns available governors for a CPU.

  ```
  iex> list_cpu_governors(:cpu0)
  [:ondemand, :userspace, :powersave, :conservative, :performance]
  ```
  """
  def list_cpu_governors(name \\ CPU, cpu) do
    GenServer.call(name, {:valid_governors, cpu})
  end

  @doc """
  Sets the governor for a CPU.

  ```
  iex> set_cpu_governor(:cpu0, :powersave)
  {:ok, :powersave}
  ```
  """
  def set_cpu_governor(name \\ CPU, cpu, governor) do
    GenServer.call(name, {:set_governor, cpu, governor})
  end

  @doc """
  Lists system LEDS.

  ```
  iex> list_leds()
  [:led0]
  ```
  """
  def list_leds(name \\ LED) do
    GenServer.call(name, :list_leds)
  end

  @doc """
  Disables an LED.
  *NOTE* This cannot be undone without an additional library which supports configuring LED triggers.

  ```
  iex> disable_led(:led0)
  :ok
  ```
  """
  def disable_led(name \\ LED, led) do
    GenServer.call(name, {:disable_led, led})
  end

  @doc false
  def list_led_triggers(name \\ LED, led) do
    GenServer.call(name, {:valid_triggers, led})
  end

  @doc false
  def set_led_trigger(name \\ LED, led, trigger) do
    GenServer.call(name, {:set_trigger, led, trigger})
  end

  @doc """
  Disables the HDMI port.

  ```
  iex> disable_hdmi()
  :ok
  ```
  """
  def disable_hdmi do
    HDMI.disable_hdmi()
    :ok
  end
end
