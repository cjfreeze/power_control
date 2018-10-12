defmodule PowerControl.Application do
  @moduledoc false

  use Application
  require Logger

  alias PowerControl.{
    CPU,
    HDMI,
    LED
  }

  def start(_type, _args) do
    :ok = CPU.startup()
    :ok = HDMI.startup()
    :ok = LED.startup()
    children = [CPU, LED]

    opts = [strategy: :one_for_one, name: PowerControl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
