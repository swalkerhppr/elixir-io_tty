defmodule IOTty.KeyHandlers do
  @moduledoc """
    GenServer responsible for holding key handler callbacks
  """
  use GenServer

  def start_link(),       do: GenServer.start_link(__MODULE__, default_config(), name: :key_handlers) 
  def start_link(:debug), do: GenServer.start_link(__MODULE__, debug_config(), name: :key_handlers) 
  def start_link(config), do: GenServer.start_link(__MODULE__, config, name: :key_handlers)

  def handle_key(key, state) do
    GenServer.call(:key_handlers, {:key_press, key, state}) 
  end

  def get_initial_state(), do: GenServer.call(:key_handlers, :initial_state) 

  def init(func_map), do: {:ok, func_map}

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

  def handle_call(:initial_state, _from, func_map), do: {:reply, func_map[:initial_state], func_map}

  @fw "\e[C"
  @bk "\e[D"
  @ret "\r"
  @bksp "\d"

  defp default_config() do
    %{
      :initial_state => {"", 0},
      @fw => &handle_fw/2,
      @bk => &handle_bk/2,
      @ret => &handle_ret/2,
      @bksp => &handle_del/2,
      :default => &handle_char/2,
     }
  end

  defp debug_config() do
    %{
      :initial_state => {}
      :default => &(IO.write(&1))
    }
  end

  defp handle_fw(@fw, {input, cursor}) do
    if String.length(input) >= cursor + 1 do
      IO.write(@fw)
      {input, cursor+1}
    else 
      {input, cursor}
    end
  end
  defp handle_bk(@bk, {input, cursor}) do
    case cursor do
      0 -> 
        {input, cursor}
      _ ->
        IO.write(@bk)
        {input, cursor-1}
    end
  end
  defp handle_ret(@ret, {input, _}) do
    IO.write("\n\e[E")
    {:stop_and_send, input}
  end

  defp handle_del(@bksp, {input, cursor}) do
    {pre, post} = cut(input, cursor)
    IO.write(@bk <> "\e[K" <> post <> back_up(post))
    case cursor do
      0 -> 
        {String.slice(pre, 0..-2) <> post , 0}
      _ ->
        {String.slice(pre, 0..-2) <> post , cursor-1}
    end
  end

  defp handle_char(<< b >>, {input, cursor}) when b in 32..126 do
    {pre, post} = cut(input, cursor)
    IO.write(<< b >> <> post <> back_up(post))
    {pre <> << b >> <> post, cursor+1}
  end
  defp handle_char(_, state), do: state

  defp cut(input, cursor), do: {String.slice(input, 0..cursor-1), String.slice(input, cursor..-1)}
  defp back_up(string), do: String.duplicate(@bk, String.length(string))

end
