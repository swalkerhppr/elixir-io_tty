defmodule IOTtyTest.ReceiverTest do
  use ExUnit.Case
  @written_output Application.get_env(:io_tty, :debug_out_file)

  setup do
    File.rm(@written_output)
    :ok
  end

end
