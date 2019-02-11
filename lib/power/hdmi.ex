defmodule PowerControl.HDMI do
  @moduledoc false
  require Logger

  @doc false
  def init do
    if Application.get_env(:power_control, :disable_hdmi) do
      disable_hdmi()
    end

    :ok
  end

  @doc false
  def disable_hdmi do
    :os.cmd('tvservice -o')
  end

  @doc false
  def enable_hdmi do
    :os.cmd('tvservice -p')
  end
end
