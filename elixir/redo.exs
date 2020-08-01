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

    {_, result} = "sh"
    |> System.cmd(["./#{buildfile}", file, basefile, "#{file}---redoing"],
      into: File.stream!("#{file}---redoing"))

    if result == 0 do
      File.rename("#{file}---redoing", file)
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
    File.touch!(".redo/#{file}.uptodate")
    else
      File.rm("#{file}---redoing")
       exit "failed to rebuild #{file}"
    end
  end

  def redo_ifchange() do
    unless System.get_env("REDOPARENT"), do: exit "no parent"
    unless File.exists?(".redo"), do: File.mkdir(".redo")

    System.argv()
    |> Enum.each(&redo_ifchange(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifchange(buildfile, redoparent) do    
    if changed(buildfile) do
      if build_if_target(buildfile) do
        record_prereq(buildfile, redoparent, :stats)
      else
        record_prereq(buildfile, redoparent, :failed)
        exit "failed to rebuild"
      end
    else 
      record_prereq(buildfile, redoparent, :stats)
    end
  end

  def record_prereq(file, redoparent, :stats) do
    md5 = :crypto.hash(:md5, file) |> Base.encode16 |> String.downcase
    parent_file = ".redo/#{redoparent}.prereqs.build"
    stats = case File.stat(file, time: :posix) do
      {:ok, %File.Stat{type: :regular, mtime: mtime}} -> %{file: file, mtime: mtime, md5: md5}
      {:ok, %File.Stat{type: _, mtime: mtime}} -> %{file: file, mtime: mtime, md5: "non-file"}
      {:error, _} -> %{file: file, mtime: "nowhen", md5: "non-file"}
    end
    |> IO.inspect()

    File.write("#{parent_file}---new", stats)
    File.rename("#{parent_file}---new", parent_file)
    |> IO.inspect()
  end

  def record_prereq(file, redoparent, :failed) do
    parent_file = ".redo/#{redoparent}.prereqs.build"
    stats = %{file: file, mtime: "nowhen", md5: "failed"}

    File.write("#{parent_file}---new", stats)
    File.rename("#{parent_file}---new", parent_file)

    exit "failed"
  end

  def changed(file) do
    file == file
  end

  def redo_ifcreate() do
    System.argv()
    |> Enum.each(&redo_ifcreate(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifcreate(buildfile, redoparent) do
    IO.inspect("ifcreate: #{buildfile}, #{redoparent}")
  end
end