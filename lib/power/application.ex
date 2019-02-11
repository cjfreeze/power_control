defmodule PowerControl.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    PowerControl.init()

    opts = [strategy: :one_for_one, name: PowerControl.Supervisor]
    Supervisor.start_link([], opts)
  end
end
