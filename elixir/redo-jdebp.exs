defmodule Redo do
  def redo() do 
    unless File.exists?(".redo"), do: File.mkdir(".redo")
    
   result = System.argv()
    |> Enum.each(&build_if_target/1)

    case result do
      :ok -> IO.puts("yay")
      {:error, msg} -> IO.puts("error: #{msg}")
    end
  end

  def build_if_target(file) do
    unrecorded = Path.wildcard(".redo/#{file}.{uptodate,prereqs,prereqsne,prereqs.build,prereqsne.build}")
    |> Enum.empty?()

    unless File.exists?(file) and unrecorded, do: build(file)
  end

  def build(file) do
    Path.wildcard(".redo/#{file}.{prereqs,prereqsne}.build")
    |> Enum.each(&File.rm/1)

    direct = "#{file}.do"
    default = Regex.replace(~r/.*([.][^.]*)$/, file, "default\\1.do")
	  basefile = Regex.replace(~r/\..*$/, file, "")
    buildfile = 
      cond do
        File.exists?(direct) -> 
          redo_ifchange(direct, file)
          direct
        File.exists?(default) ->
          redo_ifchange(default, file)
          redo_ifcreate(direct, file)
          default
        true ->
          exit "cannot build #{file}: no build script (#{default}) found"
      end

    Path.wildcard(".redo/#{file}.{uptodate,redoing}")
    |> Enum.each(&File.rm/1)

    "#{file}.redoing"
    |> File.write("./#{buildfile} #{file} #{basefile} #{file}.redoing")

    # if r=0 do
  end

  def redo_ifchange(buildfile, redoparent) do
    IO.inspect("ifchange: #{buildfile}, #{redoparent}")
  end

  def redo_ifcreate(buildfile, redoparent) do
    IO.inspect("ifcreate: #{buildfile}, #{redoparent}")
  end
end

Redo.redo()