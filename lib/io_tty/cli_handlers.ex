defmodule IOTty.CLIHandlers do
  @moduledoc """
    Default config.
    Used when :default is supplied in start_link, or when there are no arguments given to IOTty.start_link
    Implements forward, back, return, backspace, delete, home and end keys as you would expect a command line app would.
  """
  use IOTty.Keys

  alias IOTty.CLIHandlers, as: State
  alias IOTty.Helpers, as: AltIO
  defstruct input: "", cursor: 0, history: [], helem: 0


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
        AltIO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem - 1, history: add_not_empty(history, input)}
      _ -> 
        AltIO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem - 1}
    end
  end
  defp handle_press(@down, state = %State{history: history, helem: helem}) do
    new_elem = Enum.at(history, helem + 1, "")
    len = length(history)  
    case helem do
      ^len ->
        state
      _ -> 
        AltIO.write("\e[u\e[K" <> new_elem)
        %{state | input: new_elem, cursor: String.length(new_elem), helem: helem + 1}
    end
  end
  defp handle_press(@foreward, state = %State{input: input, cursor: cursor}) do
    if String.length(input) >= cursor + 1 do
      AltIO.write(@foreward)
      %{state | input: input, cursor: cursor+1}
    else 
      %{state | input: input, cursor: cursor}
    end
  end

  defp handle_press(@backward, state = %State{cursor: cursor}) do
    case cursor do
      0 -> 
        state
      _ ->
        AltIO.write(@backward)
        %{state | cursor: cursor-1}
    end
  end

  defp handle_press(@return, state = %State{input: input, history: history}) do
    AltIO.write("\n\e[E")
    {:send_line, input, %{state | input: "", cursor: 0, history: history ++ [input], helem: length(history) + 1}}
  end

  defp handle_press(@backspace, state = %State{input: input, cursor: cursor}) do
    {pre, post} = cut(input, cursor)
    case cursor do
      0 -> 
        state
      _ ->
        AltIO.write(@backward <> @clear_to_end <> post <> back_up(post))
        %{state | input: String.slice(pre, 0..-2) <> post, cursor: cursor-1}
    end
  end

  defp handle_press(@delete, state = %State{input: input, cursor: cursor}) do
    max_cursor = String.length(input)
    case cursor do
      ^max_cursor ->
        state
      _ ->
        AltIO.write(@foreward)
        handle_press(@backspace, %{state | cursor: cursor+1})
    end
  end

  defp handle_press(@home_key, state = %State{}) do
    AltIO.write(@jump_cursor)
    %{state | cursor: 0}
  end

  defp handle_press(@end_key, state = %State{input: input}) do
    AltIO.write(@jump_cursor <> String.duplicate(@foreward, String.length(input)))
    %{state | cursor: String.length(input)}
  end

  defp handle_press(<< b >>, state = %State{input: input, cursor: cursor})
    when b in 32..126 do
    {pre, post} = cut(input, cursor)
    AltIO.write(<< b >> <> @clear_to_end <> post <> back_up(post))
    %{state | input: pre <> << b >> <> post, cursor: cursor+1}
  end

  defp handle_press(_, state), do: state

  defp cut(input, cursor) when cursor == 0, do: {"", input}
  defp cut(input, cursor), do: {String.slice(input, 0..cursor-1), String.slice(input, cursor..-1)}

  defp back_up(string), do: String.duplicate(@backward, String.length(string))

  defp add_not_empty(list, ""),     do: list
  defp add_not_empty(list, string), do: list ++ [string]

end
