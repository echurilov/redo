defmodule Redo do

@parent = ""

  def redo(file \\ "../hello/all") do
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
    
    file
    |> check_type()
    |> uptodate()
  end

  defp check_type(file) do
    type = ".redo/#{file}.type"

    if !File.exists?(type) do
      if File.exists?(file) do
        type
        |> File.write("source")
      else
        type
        |> File.write("target")
      end
    end

    file
  end

  defp uptodate(file) do
    uptodate = ".redo/#{file}.uptodate"
    |> File.exists?()
    |> IO.inspect()

    if uptodate do
      ".redo/#{file}.prereqs"
      |> File.write(file)
    end
  end

end

Redo.redo()