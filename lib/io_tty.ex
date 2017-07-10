defmodule IOTty do
  @moduledoc """
    A module that provide a way to interact with console input per key by using tty_sl to process input.
    Note: to prevent error messages add  `-elixir ansi_enabled true -noinput` to the erl arguments. For escripts, add it to emu_args
  """
  alias IOTty.Helpers, as: AltIO 
  use IOTty.Keys

  @doc """
    Start the key handlers. config should be a map of key values with callbacks, :debug, :default, :disable or empty.
  """
  def start_link(config \\ :default)
  def start_link(:disable) do
     {:ok, self()}
  end
  def start_link(config) do
    IOTty.KeyHandlers.start_link(config)
    IOTty.Port.start()
  end

  @doc """
    Replacement for IO.gets. Gets a string from stdio
  """
  def gets(prompt) do
    AltIO.write(prompt <> @save_cursor)
    IOTty.Receiver.wait_for_input({:gets, self()})
  end

  @doc """
    Replacement for IO.puts displays a string.
    Makes sure that the cursor is at the beginning of the line after each new line
  """
  def puts(string) do
    AltIO.write(@line_start <> String.replace(string, @line_feed, @lfcr) <> @lfcr)
  end
  
end
