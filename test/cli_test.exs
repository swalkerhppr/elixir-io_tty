defmodule IOTtyTest.CLITest do
  use ExUnit.Case, async: false
  use IOTty.Keys

  @start_string "hello"
  alias IOTty.CLIHandlers, as: State

  setup do
    IOTty.KeyHandlers.start_link(:default)
    :ok
  end

  test "Forward Arrow Key when there is more" do
    assert handle_key(@foreward, %State{input: @start_string, cursor: 2}) === %State{input: "hello", cursor: 3}
  end

  test "Forward Arrow Key when there isn't more" do
    assert handle_key(@foreward, %State{input: @start_string, cursor: 5}) === %State{input: "hello", cursor: 5}
  end

  test "Back Arrow Key when there is more" do
    assert handle_key(@backward, %State{input: @start_string, cursor: 5}) === %State{input: "hello", cursor: 4}
  end

  test "Back Arrow Key when there isn't more" do
    assert handle_key(@backward, %State{input: @start_string, cursor: 0}) === %State{input: "hello", cursor: 0}
  end

  test "Insert after word" do
    assert handle_key("!", %State{input: @start_string, cursor: 5}) === %State{input: "hello!", cursor: 6}
  end

  test "Insert in word" do
    assert handle_key("!", %State{input: @start_string, cursor: 2}) === %State{input: "he!llo", cursor: 3}
  end

  test "Insert before word" do
    assert handle_key("!", %State{input: @start_string, cursor: 0}) === %State{input: "!hello", cursor: 1}
  end

  test "Backspace after word" do
    assert handle_key(@backspace, %State{input: @start_string, cursor: 5}) === %State{input: "hell", cursor: 4}
  end

  test "Backspace in word" do
    assert handle_key(@backspace, %State{input: @start_string, cursor: 2}) === %State{input: "hllo", cursor: 1}
  end

  test "Backspace before word" do
    assert handle_key(@backspace, %State{input: @start_string, cursor: 0}) === %State{input: "hello", cursor: 0}
  end

  test "Delete before word" do
    assert handle_key(@delete, %State{input: @start_string, cursor: 0}) === %State{input: "ello", cursor: 0}
  end

  test "Delete in word" do
    assert handle_key(@delete, %State{input: @start_string, cursor: 2}) === %State{input: "helo", cursor: 2}
  end

  test "Delete after word" do
    assert handle_key(@delete, %State{input: @start_string, cursor: 5}) === %State{input: "hello", cursor: 5}
  end

  test "Press home" do
    assert handle_key(@home_key, %State{input: @start_string, cursor: 5}) === %State{input: "hello", cursor: 0}
  end

  test "Press end" do
    assert handle_key(@end_key, %State{input: @start_string, cursor: 2}) === %State{input: "hello", cursor: 5}
  end

  test "up when input empty" do
    history = ["hello", "this", "is", "stephen"]
    assert handle_key(@up, %State{input: "", cursor: 0, history: history, helem: 4}) === %State{input: "stephen", cursor: 7, history: history, helem: 3}
  end

  test "up when input not empty" do
    history = ["hello", "this", "is", "stephen"]
    assert handle_key(@up, %State{input: "hello", cursor: 0, history: history, helem: 4}) === 
        %State{input: "stephen", cursor: 7, history: history ++ ["hello"], helem: 3}
  end

  test "up when at first history item" do
    history = ["hello", "this", "is", "stephen"]
    assert handle_key(@up, %State{input: "something", cursor: 0, history: history, helem: 0}) === %State{input: "something", cursor: 0, history: history, helem: 0}
  end

  test "down when at first history item" do
    history = ["hello", "this", "is", "stephen"]
    assert handle_key(@down, %State{input: "hello", cursor: 0, history: history, helem: 0}) === %State{input: "this", cursor: 4, history: history, helem: 1}
  end

  test "down when at last history item" do
    history = ["hello", "this", "is", "stephen"]
    assert handle_key(@down, %State{input: "something", cursor: 3, history: history, helem: 4}) === %State{input: "something", cursor: 3, history: history, helem: 4}
  end

  defp handle_key(key, state) do
    IOTty.KeyHandlers.handle_key(key, state)
  end

end
