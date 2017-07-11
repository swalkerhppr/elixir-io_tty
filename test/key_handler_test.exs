defmodule IOTtyTest.KeyHandlerTest do
  use ExUnit.Case

  @init_state %{default_called: 0, a_key_called: 0}

  defp default_func(_, state), do: %{state | default_called: state[:default_called] + 1}
  defp key_func("a", state), do: %{state | a_key_called: state[:a_key_called] + 1}

  defp default_func_map do
    %{
     :initial_state => @init_state,
     :default => &default_func/2,
     "a" => &key_func/2
     }
  end

  setup do
    IOTty.KeyHandlers.start_link(default_func_map())
    :ok
  end

  test "calling a default" do
    assert IOTty.KeyHandlers.handle_key("b", @init_state) === default_func("b", @init_state)
  end

  test "calling a key" do
    assert IOTty.KeyHandlers.handle_key("a", @init_state) === key_func("a", @init_state)
  end


end
