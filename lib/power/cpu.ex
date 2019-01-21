defmodule PowerControl.CPU do
  @moduledoc false
  @default_cpu_dir "/sys/devices/system/cpu/"
  @governors_file_name "scaling_available_governors"
  @governor_file_name "scaling_governor"
  @info_files %{
    speed: :cpuinfo_cur_freq,
    max_speed: :cpuinfo_max_freq,
    min_speed: :cpuinfo_min_freq
  }

  @doc false
  def startup do
    cpus = list_cpus()

    if(startup_governor = Application.get_env(:power_control, :cpu_governor)) do
      Enum.each(cpus, fn cpu ->
        governors = list_governors(cpu)
        {:ok, ^startup_governor} = set_governor(cpu, startup_governor, governors)
      end)
    end
    :ok
  end

  def cpu_dir do
    Application.get_env(:power_control, :cpu_dir, @default_cpu_dir)
  end

  def list_cpus do
    cpu_dir()
    |> File.ls!()
    |> Enum.filter(&filter_cpus/1)
  end

  defp filter_cpus("cpu" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_cpus(_), do: false

  def list_governors(cpu) do
    "#{cpu_dir()}#{cpu}/cpufreq/#{@governors_file_name}"
    |> File.read!()
    |> String.split()
    |> Enum.map(&:"#{&1}")
  end

  def get_governors(state, cpu) do
    get_in(state, [:cpus, cpu, :governors]) || {:error, :cpu_not_found}
  end

  def set_governor(cpu, governor, valid_governors) do
    file_path = "#{cpu_dir()}#{cpu}/cpufreq/#{@governor_file_name}"

    with {:governor, true} <- {:governor, governor in valid_governors},
         {:file, true} <- {:file, File.exists?(file_path)},
         :ok <- File.write(file_path, "#{governor}") do
      {:ok, governor}
    else
      {:governor, false} -> {:error, :invalid_governor}
      {:file, false} -> {:error, :governor_file_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def cpu_stats(cpu) do
    with true <- Map.has_key?(list_cpus(), cpu) do
      for {key, file} <- @info_files do
        info_path = "#{cpu_dir()}#{cpu}/cpufreq/#{file}"

        with {:ok, body} <- File.read(info_path),
             {value, _} <- Integer.parse(body) do
          {key, value}
        else
          _ -> {key, nil}
        end
      end
      |> Enum.filter(fn {_, value} -> value end)
      |> Enum.into(%{})
    else
      false -> {:error, :cpu_not_found}
    end
  end
end
