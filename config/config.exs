# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :io_tty, :debug_out_file, "io_tty_out.txt"
config :io_tty, :default_out, :stdio

import_config "#{Mix.env}.exs"
