defmodule IOTty.CLIHandlers do
  @moduledoc """
    Default config.
    Used when :default is supplied in start_link, or when there are no arguments given to IOTty.start_link
    Implements forward, back, return, backspace, delete, home and end keys as you would expect a command line app would.
  """

  alias IOTty.CLIHandlers, as: State
  defstruct input: "", cursor: 0, history: [], helem: 0

  @up "\e[A"
  @dn "\e[B"
  @fw "\e[C"
  @bk "\e[D"
  @ret "\r"
  @bksp "\d"
  @del "\e[3~"
  @home "\e[H"
  @enk  "\e[F"

  def map() do
    %{
      :initial_state => %State{},
      :default => &handle_press/2,
     }
  end

  defp handle_press(@up, state = %State{input: input, history: history, helem: helem}) do
    new_elem = Enum.at(history, helem - 1, nil)
    len = length(history)  
    case helem do
      0 -> 
        state
      ^len ->
        IO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem - 1, history: add_not_empty(history, input)}
      _ -> 
        IO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem - 1}
    end
  end
  defp handle_press(@dn, state = %State{history: history, helem: helem}) do
    new_elem = Enum.at(history, helem + 1, "")
    len = length(history)  
    case helem do
      ^len ->
        state
      _ -> 
        IO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem + 1}
    end
  end
  defp handle_press(@fw, state = %State{input: input, cursor: cursor}) do
    if String.length(input) >= cursor + 1 do
      IO.write(@fw)
      %{state | input: input, cursor: cursor+1}
    else 
      %{state | input: input, cursor: cursor}
    end
  end

  defp handle_press(@bk, state = %State{cursor: cursor}) do
    case cursor do
      0 -> 
        state
      _ ->
        IO.write(@bk)
        %{state | cursor: cursor-1}
    end
  end

  defp handle_press(@ret, state = %State{input: input, history: history}) do
    IO.write("\n\e[E")
    {:send_line, input, %{state | input: "", cursor: 0, history: history ++ [input], helem: length(history) + 1}}
  end

  defp handle_press(@bksp, state = %State{input: input, cursor: cursor}) do
    {pre, post} = cut(input, cursor)
    case cursor do
      0 -> 
        state
      _ ->
        IO.write(@bk <> "\e[K" <> post <> back_up(post))
        %{state | input: String.slice(pre, 0..-2) <> post, cursor: cursor-1}
    end
  end

  defp handle_press(@del, state = %State{cursor: cursor}) do
    IO.write(@fw)
    handle_press(@bksp, %{state | cursor: cursor+1})
  end

  defp handle_press(@home, state = %State{}) do
    IO.write("\e[u")
    %{state | cursor: 0}
  end

  defp handle_press(@enk, state = %State{input: input}) do
    IO.write("\e[u" <> String.duplicate(@fw, String.length(input)))
    %{state | cursor: String.length(input) - 1}
  end

  defp handle_press(<< b >>, state = %State{input: input, cursor: cursor})
    when b in 32..126 do
    {pre, post} = cut(input, cursor)
    IO.write(<< b >> <> "\e[K" <> post <> back_up(post))
    %{state | input: pre <> << b >> <> post, cursor: cursor+1}
  end

  defp handle_press(_, state), do: state

  defp cut(input, cursor) when cursor == 0, do: {"", input}
  defp cut(input, cursor), do: {String.slice(input, 0..cursor-1), String.slice(input, cursor..-1)}

  defp back_up(string), do: String.duplicate(@bk, String.length(string))

  defp add_not_empty(list, ""),     do: list
  defp add_not_empty(list, string), do: list ++ [string]

end
