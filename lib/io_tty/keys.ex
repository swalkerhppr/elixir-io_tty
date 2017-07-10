defmodule IOTty.Keys do
  @moduledoc """
    Defines use macro for compile time constants that define key presses and ANSI control codes
  """

  defmacro __using__(_) do
    quote do
      #Key presses
      #Up Arrow key
      @up           "\e[A"

      #Down Arrow key
      @down         "\e[B"

      #Right Arrow key
      @foreward     "\e[C"

      #Left Arrow key
      @backward     "\e[D"

      #Enter Key
      @return       "\r"

      #Backspace Key
      @backspace    "\d"

      #Delete Key
      @delete       "\e[3~"

      #Home Key
      @home_key     "\e[H"

      #End Key
      @end_key      "\e[F"


      #Control Characters
      #Clear everything from the cursor foreward
      @clear_to_end "\e[K"

      #Save the cursor position
      @save_cursor  "\e[s"

      #Jump to the last saved cursor position
      @jump_cursor  "\e[u"

      #Jump to the start of the line
      @line_start   "\e[E"

      #Goto next line (doesn't affect the cursor position)
      @line_feed    "\n"

      #Goto next line and reset cursor position (line feed AND carriage return)
      @lfcr         "\n\e[E"
    end
  end
end
