defmodule Redo do
  def redo(file \\ "it") do
  ".redo/**/*.uptodate"
    |> Path.wildcard(match_dot: true)
    |> Enum.each(&File.rm!/1)

    file
    |> redo_ifchange()
  end

  def redo_ifchange(file) do
    dir = Path.dirname(file)

    redo = "#{dir}/.redo"
    |> File.exists?()

    if !redo do
      File.mkdir("#{dir}/.redo")
    end
    # File.write(file, "done")
  end
end

Redo.redo()