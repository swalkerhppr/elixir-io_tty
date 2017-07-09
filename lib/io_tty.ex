defmodule IOTty do
  @moduledoc """
    A module that provide a way to interact with console input per key by using tty_sl to process input.
    Note: to prevent error messages add  `-elixir ansi_enabled true -noinput` to the erl arguments. For escripts, add it to emu_args
  """


  @doc """
    Start the key handlers. config should be a map of key values with callbacks, or :cli 
  """
  def start_link(), do: IOTty.KeyHandlers.start_link()
  def start_link(config), do: IOTty.KeyHandlers.start_link(config)

  @doc """
    Replacement for IO.gets Gets a string from input. Doesn't take a device.
  """
  def gets(prompt) do
    IO.write(prompt <> "\e[s")
    wait_for_input({:gets, self()})
  end

  defp handle_msgs(state \\ IOTty.KeyHandlers.get_initial_state(), reply_to \\ nil) do
    receive do
      {port, {:data, key}} ->  
        case handle_key(key, state) do
          {:stop_and_send, output} -> 
            send reply_to, {:reply, output}
            Port.close(port)
            {:EXIT, self(), :normal}
          new_state ->
            handle_msgs(new_state, reply_to)
        end
      {:gets, caller} -> handle_msgs(state, caller)
    end
  end
  
  defp handle_key(char_data, state) do
    IOTty.KeyHandlers.handle_key(char_data, state)
  end

  defp wait_for_input(args) do
    pid = Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof]) |> start_receiver()
    send pid, args
    receive do
      {:reply, d} -> d 
    end
  end

  defp start_receiver(port) do
    Port.connect(port, pid = spawn(&handle_msgs/0))
    pid
  end
end
