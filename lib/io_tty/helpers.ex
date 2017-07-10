defmodule IOTty.Helpers do

  @debug_file Application.get_env(:io_tty, :debug_out_file)
  @default_out Application.get_env(:io_tty, :default_out)

  @doc """
    Helper to Write to IO.
  """
  def write(device \\ @default_out, msg)
  def write(:debug, msg), do: File.write(@debug_file, msg)
  def write(:stdio, msg), do: IO.write(:stdio, msg)
end
