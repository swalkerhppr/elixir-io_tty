defmodule IOTty.Helpers do

  @debug_file Application.get_env(:io_tty, :debug_out_file)

  defp default_out do
    case env_set = Application.get_env(:io_tty, :default_out) do
      nil -> :stdio
      _   -> env_set 
    end
  end

  @doc """
    Helper to Write to IO.
  """
  def write(device \\ default_out(), msg)
  def write(:debug, msg), do: File.write(@debug_file, msg)
  def write(:stdio, msg), do: IO.write(:stdio, msg)
end
