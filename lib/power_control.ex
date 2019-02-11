defmodule PowerControl do
  @moduledoc """
  `PowerControl` is a library that enables runtime configuration of embedded linux for power conservation or performance via native elixir.

  ## Getting Started

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
    disable_leds: true,
    disable_hdmi: true
  ```
  The CPU Governor determines CPU clock speed behavior. Different devices can have different available governors. For more information about determining available governors, see the "Runtime Functionality" section below.

  `disable_leds` disables all system leds. To selectively disable them, you may want to use the functions `list_leds/0` and `disable_led/1` manually. More complex LED management can be done with [`Nerves.Leds`](https://github.com/nerves-project/nerves_leds).

  `disable_hdmi` disables the onboard hdmi of the pi. This may also disable other forms of video on hats or other peripherals, but this is not tested.

  ## Runtime Functionality

  `PowerControl` also allows you fetch information about your system and configure some settings during runtime, for example:

  ```elixir
  iex> list_cpus()
  {:ok, [:cpu0]}
  iex> cpu_info(:cpu0).speed
  700000
  iex> list_cpu_governors(:cpu0)
  {:ok, [:ondemand, :userspace, :powersave, :conservative, :performance]}
  iex> set_cpu_governor(:cpu0, :performance)
  {:ok, :performance}
  iex> cpu_info(:cpu0).speed
  1000000
  ```

  The functions `list_cpus/0` and `list_cpu_governors/1` can be used to determine what governors you have available on your device for configuration.

  ## Other Errors and Advanced Configuration

  All Led and CPU functions can return Elixir `File` error messages such as `:enoent`, which generally indicates you have configured the directories improperly for your specific device (unlikely) or that `PowerControl` does not support your device (most likely). In the unlikely case that your device can be supported by `PowerControl` but you must manually configure the directories, the config keys are `cpu_dir` and `led_dir`. I do not currently support configuring filenames.
  """
  require Logger
  alias PowerControl.{CPU, LED, HDMI}

  @startup_governor_warning "[PowerControl] No startup CPU Governor configured, device will use default."
  @directory_warning_cpu "[PowerControl] Could not find CPU directory, are you sure this is a Nerves device?"
  @directory_warning_led "[PowerControl] Could not find LED directory, are you sure this is a Nerves device?"
  @doc false
  def init do
    case CPU.init() do
      {:error, :no_startup_governor_configured} ->
        Logger.warn(@startup_governor_warning)

      {:error, :enoent} ->
        Logger.warn(@directory_warning_cpu)

      _ ->
        :ok
    end

    case LED.init() do
      {:error, :enoent} ->
        Logger.warn(@directory_warning_led)

      _ ->
        :ok
    end

    HDMI.init()
    :ok
  end

  @doc """
  Lists system CPUS.

  ```
  iex> list_cpus()
  {:ok, [:cpu0]}
  ```
  """
  def list_cpus do
    CPU.list_cpus()
  end

  @doc """
  Returns an info map for a CPU.

  ```
  iex> cpu_info(:cpu0)
  %{max_speed: 1000000, min_speed: 700000, speed: 1000000}
  ```
  """
  def cpu_info(cpu) do
    CPU.cpu_info(cpu)
  end

  @doc """
  Returns available governors for a CPU.

  ```
  iex> list_cpu_governors(:cpu0)
  {:ok, [:ondemand, :userspace, :powersave, :conservative, :performance]}
  ```
  """
  def list_cpu_governors(cpu) do
    CPU.list_governors(cpu)
  end

  @doc """
  Sets the governor for a CPU.

  ```
  iex> set_cpu_governor(:cpu0, :powersave)
  {:ok, :powersave}

  iex> set_cpu_governor(:cpu0, :invalid)
  {:error, :invalid_governor}

  # Running on non-nerves device or with bad governor file settings
  iex> set_cpu_governor(:cpu0, :powersave)
  {:error, :governor_file_not_found}
  ```
  """
  def set_cpu_governor(cpu, governor) do
    CPU.set_governor(cpu, governor)
  end

  @doc """
  Lists system LEDS.

  ```
  iex> list_leds()
  {:ok, [:led0]}
  ```
  """
  def list_leds do
    LED.list_leds()
  end

  @doc """
  Disables an LED.

  Uses a simple retry system if it fails, retries 2 times then gives up.
  To re-enable the LED or further configure LED settings, I reccomend [`Nerves.Leds`](https://github.com/nerves-project/nerves_leds).

  ```
  iex> disable_led(:led0)
  :ok

  iex> disable_led(:invalid_led)
  {:error, ...}
  ```
  """
  def disable_led(led) do
    LED.disable_led(led)
  end

  @doc """
  Disables the HDMI port.

  Returns `:ok` regardless of failure or success, but almost always succeeds.

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
