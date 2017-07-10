defmodule IOTty.KeyHandlers do
  @moduledoc """
    GenServer responsible for holding key handler callbacks
  """
  use GenServer

  @doc """
    Start the key handlers, should be called from the main IOTty.start_link
  """
  def start_link(:default), do: GenServer.start_link(__MODULE__, IOTty.CLIHandlers.map(), name: :key_handlers) 
  def start_link(:debug), do: GenServer.start_link(__MODULE__, debug_config(), name: :key_handlers) 
  def start_link(config), do: GenServer.start_link(__MODULE__, config, name: :key_handlers)

  @doc """
    Handle a single key press
  """
  def handle_key(key, state) do
    GenServer.call(:key_handlers, {:key_press, key, state}) 
  end

  @doc """
    Get the intial state provided in config
  """
  def get_initial_state(), do: GenServer.call(:key_handlers, :initial_state) 

  def init(func_map), do: {:ok, func_map}

  @doc """
    Handle retreiving the callback from config, call it and return the key with the new state
  """
  def handle_call({:key_press, key, state}, _from, func_map) do
    ret = case Map.fetch(func_map, key) do
      {:ok, func} -> func.(key, state)
      :error ->
        case Map.fetch(func_map, :default) do
          {:ok, func} -> func.(key, state)
          :error -> state
        end
    end
    {:reply, ret, func_map}
  end

  @doc """
    Handle retreiving the intial state variable
  """
  def handle_call(:initial_state, _from, func_map), do: {:reply, func_map[:initial_state], func_map}


  @doc """
    Debug config.
    Used when :debug is supplied in start_link, or when given to IOTty.start_link
    Only outputs the string equivalents to key presses.
    Helpful when creating callback map.
  """
  def debug_config() do
    %{
      :initial_state => {},
      :default      => &handle_debug/2
     }
   end

  defp handle_debug(key, state) do
    IOTty.puts("KEY: #{inspect key}\e[E")
    state
  end

end
