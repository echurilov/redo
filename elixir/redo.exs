defmodule Redo do
  def redo() do 
    unless File.exists?(".redo"), do: File.mkdir(".redo")
    
   result = System.argv()
    |> Enum.each(&build_if_target/1)

    case result do
      :ok -> IO.puts("rebuilt all")
      {:error, msg} -> IO.puts("error: #{msg}")
      _ -> "wat: #{result}"
    end
  end

  def build_if_target(file) do
    unrecorded = ".redo/#{file}.{uptodate,prereqs,prereqsne,prereqs.build,prereqsne.build}"
    |> Path.wildcard()
    |> Enum.empty?()

    unless File.exists?(file) and unrecorded, do: build(file)
  end

  def build(file) do
    ".redo/#{file}.{prereqs,prereqsne}.build"
    |> Path.wildcard()
    |> Enum.each(&File.rm/1)

    direct = "#{file}.do"
    default = Regex.replace(~r/.*([.][^.]*)$/, file, "default\\1") <> ".do"
	  basefile = Regex.replace(~r/\..*$/, file, "")
    buildfile = cond do
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

    ".redo/#{file}{.uptodate,---redoing}"
    |> Path.wildcard()
    |> Enum.each(&File.rm/1)

    placeholder = "#{file}---redoing"

    {_, result} = "sh"
    |> System.cmd(["./#{buildfile}", file, basefile, placeholder],
      into: File.stream!(placeholder))

    if result == 0 do
      File.rename(placeholder, file)
      IO.puts("rebuilt #{file}")
      if File.exists?(".redo/#{file}.prereqs.build") do
        File.rename(".redo/#{file}.prereqs.build", ".redo/#{file}.prereqs")
      else 
        File.rm(".redo/#{file}.prereqs")
      end
      if File.exists?(".redo/#{file}.prereqsne.build") do
        File.rename(".redo/#{file}.prereqsne.build", ".redo/#{file}.prereqsne")
      else 
        File.rm(".redo/#{file}.prereqsne")
      end
      "#{file}.uptodate"
      |> File.write("y")
    else
      File.rm(placeholder)
       exit "failed to rebuild #{file}"
    end
  end

  def redo_ifchange() do
    System.argv()
    |> Enum.each(&redo_ifchange(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifchange(buildfile, redoparent) do
    IO.inspect("ifchange: #{buildfile}, #{redoparent}")
  end

  def redo_ifcreate() do
    System.argv()
    |> Enum.each(&redo_ifcreate(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifcreate(buildfile, redoparent) do
    IO.inspect("ifcreate: #{buildfile}, #{redoparent}")
  end
end