defmodule PowerControl.LED do
  @moduledoc false
  @default_led_dir "/sys/class/leds/"
  # @trigger_file_name "trigger"
  @brightness_file_name "brightness"

  @doc false
  def startup do
    path = Application.get_env(:power_control, :led_dir, @default_led_dir)
    leds = list_leds(path)

    if(Application.get_env(:power_control, :disable_leds, true)) do
      Enum.each(leds, fn led ->
        disable_led(path, led)
      end)
    end

    :ok
  end

  def led_dir do
    Application.get_env(:power_control, :led_dir, @default_led_dir)
  end

  def list_leds(dir) do
    dir
    |> File.ls!()
    |> Enum.filter(&filter_leds/1)
  end

  defp filter_leds("led" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_leds(_), do: false

  def disable_led(dir, led, tries \\ 0) do
    "#{dir}#{led}/#{@brightness_file_name}"
    |> File.write("0")
    |> case do
      {:error, _} when tries < 5 ->
        Process.sleep(tries * 1000)
        disable_led(dir, led, tries + 1)

      _ ->
        :ok
    end
  end

  # defp do_list_triggers(dir, led) do
  #   "#{dir}#{led}/#{@trigger_file_name}"
  #   |> File.read!()
  #   |> String.split()
  #   |> Enum.map(&format_triggers/1)
  # end

  # defp format_triggers("[" <> rest) do
  #   rest
  #   |> String.trim_trailing("]")
  #   |> format_triggers()
  # end

  # defp format_triggers(trigger), do: :"#{trigger}"

  # defp get_triggers(state, led) do
  #   get_in(state, [:leds, led, :triggers]) || {:error, :led_not_found}
  # end

  # defp set_trigger(path, led, trigger, valid_triggers) do
  #   file_path = "#{path}#{led}/#{@trigger_file_name}"

  #   with {:trigger, true} <- {:trigger, trigger in valid_triggers},
  #        {:file, true} <- {:file, File.exists?(file_path)},
  #        :ok <- File.write(file_path, "#{trigger}") do
  #     {:ok, trigger}
  #   else
  #     {:trigger, false} -> {:error, :invalid_trigger}
  #     {:file, false} -> {:error, :trigger_file_not_found}
  #     {:error, reason} -> {:error, reason}
  #   end
  # end
end
