defmodule PowerControl.MixProject do
  use Mix.Project

  def project do
    [
      app: :power_control,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A library for managing power consumption of embedded devices.",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PowerControl.Application, []}
    ]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [
      maintainers: ["Chris Freeze"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/cjfreeze/power_control"}
    ]
  end
end
