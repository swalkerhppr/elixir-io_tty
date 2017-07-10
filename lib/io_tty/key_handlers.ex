defmodule IOTty.KeyHandlers do
  @moduledoc """
    GenServer responsible for holding key handler callbacks
  """
  use GenServer

  @doc """
    Start the key handlers, should be called from the main IOTty.start_link
  """
  def start_link(:default), do: GenServer.start_link(__MODULE__, default_config(), name: :key_handlers) 
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

  @fw "\e[C"
  @bk "\e[D"
  @ret "\r"
  @bksp "\d"
  @del "\e[3~"
  @home "\e[H"
  @enk  "\e[F"

  @doc """
    Default config.
    Used when :default is supplied in start_link, or when there are no arguments given to IOTty.start_link
    Implements forward, back, return, backspace, delete, home and end keys as you would expect a command line app would.
  """
  def default_config() do
    %{
      :initial_state => {"", 0},
      :default => &handle_press/2,
     }
  end

  @doc """
    Debug config.
    Used when :debug is supplied in start_link, or when given to IOTty.start_link
    Only outputs the string equivalents to key presses.
    Helpful when creating callback map
  """
  def debug_config() do
    %{
      :initial_state => {},
      :default      => &handle_debug/2
     }
   end

  defp handle_debug(key, state) do
    IO.puts("KEY: #{inspect key}\e[E")
    state
  end

  defp handle_press(@fw, {input, cursor}) do
    if String.length(input) >= cursor + 1 do
      IO.write(@fw)
      {input, cursor+1}
    else 
      {input, cursor}
    end
  end
  defp handle_press(@bk, {input, cursor}) do
    case cursor do
      0 -> 
        {input, cursor}
      _ ->
        IO.write(@bk)
        {input, cursor-1}
    end
  end
  defp handle_press(@ret, state = {input, _}) do
    IO.write("\n\e[E")
    {:send_line, input, {"", 0}}
  end

  defp handle_press(@bksp, {input, cursor}) do
    {pre, post} = cut(input, cursor)
    case cursor do
      0 -> 
        {post , 0}
      _ ->
        IO.write(@bk <> "\e[K" <> post <> back_up(post))
        {String.slice(pre, 0..-2) <> post , cursor-1}
    end
  end

  defp handle_press(@del, {input, cursor}) do
    IO.write(@fw)
    handle_press(@bksp, {input, cursor+1})
  end

  defp handle_press(@home, {input, _}) do
    IO.write("\e[u")
    {input, 0}
  end

  defp handle_press(@enk, {input, _}) do
    IO.write("\e[u" <> String.duplicate(@fw, String.length(input)))
    {input, String.length(input) - 1}
  end

  defp handle_press(<< b >>, {input, cursor}) when b in 32..126 do
    {pre, post} = cut(input, cursor)
    IO.write(<< b >> <> post <> back_up(post))
    {pre <> << b >> <> post, cursor+1}
  end
  defp handle_press(_, state), do: state

  defp cut(input, cursor), do: {String.slice(input, 0..cursor-1), String.slice(input, cursor..-1)}
  defp back_up(string), do: String.duplicate(@bk, String.length(string))

end
