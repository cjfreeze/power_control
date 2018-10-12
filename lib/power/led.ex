defmodule PowerControl.LED do
  @moduledoc false
  use GenServer
  @default_led_dir "/sys/class/leds/"
  @trigger_file_name "trigger"
  @brightness_file_name "brightness"

  @doc false
  def startup do
    path = Application.get_env(:power_control, :led_dir, @default_led_dir)
    leds = do_list_leds(path)

    if(Application.get_env(:power_control, :disable_leds, true)) do
      Enum.each(leds, fn led ->
        disable_led(path, led)
      end)
    end

    :ok
  end

  def init(_opts) do
    led_dir = Application.get_env(:power_control, :led_dir, @default_led_dir)
    leds = do_list_leds(led_dir)

    led_map =
      for led <- leds, into: %{} do
        led_state = %{
          triggers: do_list_triggers(led_dir, led)
        }

        {:"#{led}", led_state}
      end

    state = %{
      led_dir: led_dir,
      leds: led_map
    }

    {:ok, state}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_call(:list_leds, _from, %{leds: leds} = state) do
    {:reply, Map.keys(leds), state}
  end

  def handle_call({:disable_led, led}, _from, %{led_dir: path} = state) do
    {:reply, disable_led(path, led), state}
  end

  def handle_call({:valid_triggers, led}, _from, state) do
    {:reply, get_triggers(state, led), state}
  end

  def handle_call({:set_trigger, led, trigger}, _from, %{led_dir: path} = state) do
    response =
      with triggers when is_list(triggers) <- get_triggers(state, led),
           {:ok, ^trigger} <- set_trigger(path, led, trigger, triggers) do
        {:ok, trigger}
      else
        {:error, reason} -> {:error, reason}
      end

    {:reply, response, state}
  end

  defp do_list_leds(path) do
    path
    |> File.ls!()
    |> Enum.filter(&filter_leds/1)
  end

  defp filter_leds("led" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_leds(_), do: false

  defp disable_led(path, led, tries \\ 0) do
    "#{path}#{led}/#{@brightness_file_name}"
    |> File.write("0")
    |> case do
      {:error, _} when tries < 5 ->
        Process.sleep(tries * 1000)
        disable_led(path, led, tries + 1)

      _ ->
        :ok
    end
  end

  defp do_list_triggers(path, led) do
    "#{path}#{led}/#{@trigger_file_name}"
    |> File.read!()
    |> String.split()
    |> Enum.map(&format_triggers/1)
  end

  defp format_triggers("[" <> rest) do
    rest
    |> String.trim_trailing("]")
    |> format_triggers()
  end

  defp format_triggers(trigger), do: :"#{trigger}"

  defp get_triggers(state, led) do
    get_in(state, [:leds, led, :triggers]) || {:error, :led_not_found}
  end

  defp set_trigger(path, led, trigger, valid_triggers) do
    file_path = "#{path}#{led}/#{@trigger_file_name}"

    with {:trigger, true} <- {:trigger, trigger in valid_triggers},
         {:file, true} <- {:file, File.exists?(file_path)},
         :ok <- File.write(file_path, "#{trigger}") do
      {:ok, trigger}
    else
      {:trigger, false} -> {:error, :invalid_trigger}
      {:file, false} -> {:error, :trigger_file_not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
