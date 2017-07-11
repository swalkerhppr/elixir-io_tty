# elixir-io_tty

Elixir module to handle key presses from the terminal in elixir when using gets.
It uses tty_sl to handle input.

If you find any bugs or have feature requests, I am open to pull requests or let me know and I can look into it.

## Usage

Add `:io_tty, git: "https://github.com/swalker90/elixir-io_tty.git", tag: "v1.0.0"` to your deps in mix.exs
For command line applications using escript add `emu_args: "-elixir ansi_enabled true -noinput"` to your escript definition.

To enable forward and back keys in your application configuration add `worker(IOTty, [])` to your application children and use IOTty.gets to get strings.
This will load default callbacks to handle each key when doing a IOTty.gets to make it so that forward, back, up, down, end and home keys work like an interactive command line application.

There are 3 modes to use this module:

  - default -- use worker(IOTty, []). Enables the use of left and right arrow keys
  - debug -- use worker(IOTty, [:debug]). Shows the key values that are pressed.
  - custom -- use worker(IOTty, [my_func_callback_map]). Defines a custom behaviour using callbacks. See below.

Only gets and puts are implemented.

Trying to use it while in an IEX session will give errors, because it is already using tty_sl to handle input/output.
This module provides the functionality to use tty_sl outside of IEX.

## Callbacks

You may also define callbacks to be called instead of the default behaviour.
The callback map is formatted in the following way:
```
  %{
    :initial_state => {some_state_var, some_other_var},
    :default => &default_func/2,
    "\e[A" => &up_func/2,
  }
```

Each callback takes the key pressed and a state and returns the modified state.
If the key is not found in the callback map, :default is called.
If :default does not exist, nothing will happen.
State should contain anything to be held between key presses.
The initial state is determined by the `:initial_state` key in the callback map.
A callback can also return `{:send_line, output, state}` which sends output back to the calling process.

For example, here are the default callbacks for handling printable characters and the return key:
```
  defp handle_press(@ret, state = %State{input: input, history: history, helem: helem}) do
    IO.write("\n\e[E")
    {:send_line, input, %{state | input: "", cursor: 0, history: history ++ [input], helem: helem + 1}}
  end

  defp handle_press(<< b >>, state = %State{input: input, cursor: cursor})
    when b in 32..126 do
    {pre, post} = cut(input, cursor)
    IO.write(<< b >> <> "\e[K" <> post <> back_up(post))
    %{state | input: pre <> << b >> <> post, cursor: cursor+1}
  end
```

where the state map of input, cursor position, history and where in the history you are.

Note: When io_tty is active, input will not be output to the screen. _Pressing a key will only trigger the assigned callback._
In other words, callbacks are responsible for outputing keys to the screen.

## Output

Mixing `IO.puts` and `IOTty.gets` results in strange output.
When using `IO.puts` with IOTty, the new line is interpreted as "move to the next line" and not "move to the start of the next line".
This can cause output to look a like this:
```
First Line
          Second Line
                     Third Line
```
To fix this, use `IOTty.puts` instead of `IO.puts`.
`IOTty.puts` changes the new line character to move to the first start of the next line.

If you would like to format input yourself, use ASCI control characters with the built in `IO.write` 
