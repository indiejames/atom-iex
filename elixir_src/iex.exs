defmodule AtomIEx do
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

  def run_all_tests do
    {rval, _} = System.cmd("mix", ["test", "--color"], [])
    IO.puts rval
  end

  def run_test(file) do
    {rval, _} = System.cmd("mix", ["test", "--color", file])
    IO.puts rval
  end

  def run_test(file, line_num) do
    {rval, _} = System.cmd("mix", ["test", "--color", "#{file}:#{line_num}"])
    IO.puts rval
  end

end
