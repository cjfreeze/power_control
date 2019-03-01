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
  def init do
    with {:ok, cpus} <- list_cpus(),
         startup_governor when not is_nil(startup_governor) <-
           Application.get_env(:power_control, :cpu_governor) do
      Enum.each(cpus, fn cpu ->
        {:ok, ^startup_governor} = set_governor(cpu, startup_governor)
      end)
    else
      nil -> {:error, :no_startup_governor_configured}
      error -> error
    end
  end

  @doc false
  def cpu_dir do
    Application.get_env(:power_control, :cpu_dir, @default_cpu_dir)
  end

  @doc false
  def list_cpus do
    cpu_dir()
    |> File.ls()
    |> case do
      {:ok, list} ->
        cpus =
          list
          |> Enum.filter(&filter_cpus/1)
          |> Enum.map(&String.to_atom/1)

        {:ok, cpus}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp filter_cpus("cpu" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_cpus(_), do: false

  @doc false
  def list_governors(cpu) do
    "#{cpu_dir()}#{cpu}/cpufreq/#{@governors_file_name}"
    |> File.read()
    |> case do
      {:ok, contents} ->
        governors =
          contents
          |> String.split()
          |> Enum.map(&:"#{&1}")

        {:ok, governors}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def set_governor(cpu, governor) do
    file_path = "#{cpu_dir()}#{cpu}/cpufreq/#{@governor_file_name}"

    with {:file, true} <- {:file, File.exists?(file_path)},
         {:ok, valid_governors} <- list_governors(cpu),
         {:governor, true} <- {:governor, governor in valid_governors},
         :ok <- File.write(file_path, "#{governor}") do
      {:ok, governor}
    else
      {:file, false} -> {:error, :governor_file_not_found}
      {:governor, false} -> {:error, :invalid_governor}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def cpu_info(cpu) do
    with {:ok, cpus} <- list_cpus(),
         ^cpu <- Enum.find(cpus, &(&1 == cpu)) do
      for {key, file} <- @info_files do
        info_path = "#{cpu_dir()}/#{cpu}/cpufreq/#{file}"

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
