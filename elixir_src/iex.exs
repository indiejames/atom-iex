defmodule AtomIEx do
  @moduledoc "Helper functions to support interaction with IEx using the iex
  package for the Atom editor"

  @doc "Reset the application"
  def reset do
    Mix.Task.reenable "compile.elixir"
    try do
      Application.stop(Mix.Project.config[:app]);
      Mix.Task.run "compile.elixir";
      Application.start(Mix.Project.config[:app], :permanent)
    catch;
      :exit, _ -> "Application failed to start"
    end
    :ok
  end

  @doc "Run all the tests defined in the application"
  def run_all_tests do
    {rval, _} = System.cmd("mix", ["test", "--color"], [])
    IO.puts rval
  end

  @doc "Run the currently open test file"
  def run_test(file) do
    {rval, _} = System.cmd("mix", ["test", "--color", file])
    IO.puts rval
  end

  @doc "Run the currently selected test"
  def run_test(file, line_num) do
    {rval, _} = System.cmd("mix", ["test", "--color", "#{file}:#{line_num}"])
    IO.puts rval
  end

  defmodule Comment do
    @moduledoc "Provides a 'comment' macro to allow blocks of code to be ignored
    to facilitate running them as small tests in IEx during interactive
    development.

    Usage:
    ```
    comment do
      some code
    end
    ```"
    defmacro comment(_expr) do
    end
  end
end
