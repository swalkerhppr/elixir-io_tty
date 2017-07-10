defmodule IOTty do
  @moduledoc """
    A module that provide a way to interact with console input per key by using tty_sl to process input.
    Note: to prevent error messages add  `-elixir ansi_enabled true -noinput` to the erl arguments. For escripts, add it to emu_args
  """


  @doc """
    Start the key handlers. config should be a map of key values with callbacks, :debug or empty.
  """
  def start_link(config \\ :default) do
    IOTty.KeyHandlers.start_link(config)
    start_port()
  end

  @doc """
    Replacement for IO.gets. Gets a string from stdio
  """
  def gets(prompt) do
    IO.write(prompt <> "\e[s")
    wait_for_input({:gets, self()})
  end

  @doc """
    Replacement for IO.puts displays a string.
    Makes sure that the cursor is at the beginning of the line after each new line
  """
  def puts(string) do
    IO.write("\e[E" <> String.replace(string, "\n", "\n\e[E") <> "\n\e[E")
  end

  defp handle_msgs(state \\ IOTty.KeyHandlers.get_initial_state(), reply_to \\ nil) do
    receive do
      {_port, {:data, key}} ->  
        case handle_key(key, state) do
          {:send, output, new_state} -> 
            send reply_to, {:reply, output}
            handle_msgs(new_state, nil)
          new_state ->
            handle_msgs(new_state, reply_to)
        end
      {:gets, caller} -> handle_msgs(state, caller)
    end
  end

  defp start_port do
    pid = Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])
    |> start_receiver()
    Process.register(pid, :input_receiver)
    {:ok, pid}
  end
  
  defp handle_key(char_data, state) do
    IOTty.KeyHandlers.handle_key(char_data, state)
  end

  defp wait_for_input(args) do
    send :input_receiver, args
    receive do
      {:reply, d} -> d 
    end
  end

  defp start_receiver(port) do
    Port.connect(port, pid = spawn(&handle_msgs/0))
    pid
  end
end
