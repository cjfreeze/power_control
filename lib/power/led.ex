defmodule PowerControl.LED do
  @moduledoc false
  @default_led_dir "/sys/class/leds/"
  @brightness_file_name "brightness"

  @doc false
  def init do
    with {:ok, leds} <- list_leds() do
      if(Application.get_env(:power_control, :disable_leds, true)) do
        Enum.each(leds, fn led ->
          disable_led(led)
        end)
      end
    end
  end

  @doc false
  def led_dir do
    Application.get_env(:power_control, :led_dir, @default_led_dir)
  end

  @doc false
  def list_leds do
    led_dir()
    |> File.ls()
    |> case do
      {:ok, list} ->
        {:ok, Enum.filter(list, &filter_leds/1)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp filter_leds("led" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_leds(_), do: false

  @doc false
  def disable_led(led, tries \\ 0) do
    "#{led_dir()}#{led}/#{@brightness_file_name}"
    |> File.write("0")
    |> case do
      {:error, _} when tries < 3 ->
        Process.sleep(tries * 100)
        disable_led(led, tries + 1)

      _ ->
        :ok
    end
  end
end
