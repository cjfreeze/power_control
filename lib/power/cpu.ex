defmodule PowerControl.CPU do
  @moduledoc false
  use GenServer

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
    cpu_dir = Application.get_env(:power_control, :cpu_dir, @default_cpu_dir)
    cpus = do_list_cpus(cpu_dir)

    if(startup_governor = Application.get_env(:power_control, :cpu_governor)) do
      Enum.each(cpus, fn cpu ->
        governors = do_list_governors(cpu_dir, cpu)
        {:ok, ^startup_governor} = set_governor(cpu_dir, cpu, startup_governor, governors)
      end)
    end
  end

  def init(_opts) do
    cpu_dir = Application.get_env(:power_control, :cpu_dir, @default_cpu_dir)
    cpus = do_list_cpus(cpu_dir)

    cpu_map =
      for cpu <- cpus, into: %{} do
        cpu_state = %{
          governors: do_list_governors(cpu_dir, cpu)
        }

        {:"#{cpu}", cpu_state}
      end

    state = %{
      cpu_dir: cpu_dir,
      cpus: cpu_map
    }

    {:ok, state}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handle_call(:list_cpus, _from, %{cpus: cpus} = state) do
    {:reply, Map.keys(cpus), state}
  end

  def handle_call({:cpu_stats, cpu}, _from, %{cpu_dir: path, cpus: cpus} = state) do
    response =
      with true <- Map.has_key?(cpus, cpu) do
        for {key, file} <- @info_files do
          info_path = "#{path}#{cpu}/cpufreq/#{file}"

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

    {:reply, response, state}
  end

  def handle_call({:valid_governors, cpu}, _from, state) do
    {:reply, get_governors(state, cpu), state}
  end

  def handle_call({:set_governor, cpu, governor}, _from, %{cpu_dir: path} = state) do
    response =
      with governors when is_list(governors) <- get_governors(state, cpu),
           {:ok, ^governor} <- set_governor(path, cpu, governor, governors) do
        {:ok, governor}
      else
        {:error, reason} -> {:error, reason}
      end

    {:reply, response, state}
  end

  defp do_list_cpus(path) do
    path
    |> File.ls!()
    |> Enum.filter(&filter_cpus/1)
  end

  defp filter_cpus("cpu" <> rest) do
    Integer.parse(rest) != :error
  end

  defp filter_cpus(_), do: false

  defp do_list_governors(path, cpu) do
    "#{path}#{cpu}/cpufreq/#{@governors_file_name}"
    |> File.read!()
    |> String.split()
    |> Enum.map(&:"#{&1}")
  end

  defp get_governors(state, cpu) do
    get_in(state, [:cpus, cpu, :governors]) || {:error, :cpu_not_found}
  end

  defp set_governor(path, cpu, governor, valid_governors) do
    file_path = "#{path}#{cpu}/cpufreq/#{@governor_file_name}"

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
end
