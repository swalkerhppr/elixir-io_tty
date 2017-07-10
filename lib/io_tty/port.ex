defmodule IOTty.Port do
  def start do
    {
      :ok, 
      open_port() |> IOTty.Receiver.start()
    }
  end

  defp open_port do
    Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof]) 
  end
end
