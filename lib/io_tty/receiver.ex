defmodule IOTty.Receiver do

  def start(port) do
    Port.connect(port, pid = spawn(&handle_msgs/0))
    Process.register(pid, :input_receiver)
    pid
  end

  def wait_for_input(args) do
    send :input_receiver, args
    receive do
      {:reply, d} -> d 
    end
  end

  defp handle_msgs(state \\ IOTty.KeyHandlers.get_initial_state(), reply_to \\ nil) do
    receive do
      {_port, {:data, key}} ->  
        case IOTty.KeyHandlers.handle_key(key, state) do
          {:send_line, output, new_state} -> 
            send reply_to, {:reply, output}
            handle_msgs(new_state, nil)
          new_state ->
            handle_msgs(new_state, reply_to)
        end
      {:gets, caller} -> handle_msgs(state, caller)
    end
  end

end
