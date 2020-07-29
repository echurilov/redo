defmodule Redo do
  def redo(file) do
    Path.dirname(file)
    |> (&"#{&1}/.redo/**/*.uptodate").()
    |> Path.wildcard(match_dot: true)
    |> Enum.each(&File.rm!/1)

    file
    |> redo_ifchange()
  end

  def redo_ifchange(file) do
    dir = Path.dirname(file)

    File.mkdir("#{dir}/.redo")
    File.write(file, "done")
  end
end

Redo.redo("it")