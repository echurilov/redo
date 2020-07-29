defmodule Redo do
  def redo(file) do
    Path.wildcard(".redo/**/*.uptodate", match_dot: true)
    |> Enum.each( &File.rm!/1 )

    file
    |> redo_ifchange()
  end

  def redo_ifchange(args) do
    File.mkdir(".redo")
    File.write(args, "done")
  end
end

Redo.redo("it")