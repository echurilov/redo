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
    IO.puts("building #{file}")

    ".redo/#{file}.{prereqs.build,prereqsne.build,uptodate}"
    |> Path.wildcard()
    |> Enum.each(&File.rm/1)

    {_, code} = System.cmd(
      "sh", [
        "./#{buildfile(file)}",
        file,
        Regex.replace(~r/\..*$/, file, ""),
        "#{file}---redoing"
      ], into: File.stream!("#{file}---redoing"),
      env: [{"REDOPARENT", file}]
    )

    if code == 0 do
      File.rename("#{file}---redoing", file)
      IO.puts("rebuilt #{file}")
      update(".redo/#{file}.prereqs")
      update(".redo/#{file}.prereqsne")
      File.touch!(".redo/#{file}.uptodate")
    else
      File.rm("#{file}---redoing")   
    end
  end

  def buildfile(file) do
    direct = "#{file}.do"
    default = Regex.replace(~r/.*([.][^.]*)$/, file, "default\\1") <> ".do"
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
  end

  def update(path) do
    if File.exists?("#{path}.build") do
      File.rename("#{path}.build", "#{path}")
    else 
      File.rm("#{path}")
    end
  end

  def redo_ifchange() do
    unless System.get_env("REDOPARENT"), do: exit "no parent"
    unless File.exists?(".redo"), do: File.mkdir(".redo")

    System.argv()
    |> Enum.each(&redo_ifchange(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifchange(file, redoparent) do
    (if changed(file), do: build_if_target(file), else: :ok)
    |> record_prereq(file, redoparent)
  end

  def record_prereq(:ok, file, redoparent) do 
    parent_file = ".redo/#{redoparent}.prereqs.build"
    stats = case File.stat(file, time: :posix) do
      {:ok, %File.Stat{type: :regular, mtime: mtime}} -> "#{file} #{mtime} #{md5(file)}"
      {:ok, %File.Stat{type: _, mtime: mtime}} -> "#{file} #{mtime} non-file"
      {:error, _} -> "#{file} nowhen non-file"
    end

    File.write("#{parent_file}---new", stats)
    File.rename("#{parent_file}---new", parent_file)
  end

  def record_prereq(nil, file, redoparent) do
    parent_file = ".redo/#{redoparent}.prereqs.build"
    stats = "#{file} nowhen failed"

    File.write("#{parent_file}---new", stats)
    File.rename("#{parent_file}---new", parent_file)

    exit "cannot build #{file} with parent #{redoparent}"
  end

  def changed(file) do
    deleted = not File.exists?(file)

    prereqs_outdated = case File.read(".redo/#{file}.prereqs") do
      {:error, _} -> false
      {:ok, contents} ->
      contents
      |> String.split("/n")
      |> Enum.any?(fn entry ->
        [prereq, mtime, md5] = String.split(entry)
        if changed(prereq), do: build_if_target(prereq)
        case File.stat(prereq, time: :posix) do
          {:error, _} -> true
          {:ok, %File.Stat{mtime: ^mtime}} -> md5 == md5(prereq)
          {:ok, _} -> false
        end
      end)
    end

    prereqsne_created = case File.read(".redo/#{file}.prereqsne") do
      {:error, _} -> false
      {:ok, contents} ->
      contents
      |> String.split("/n")
      |> Enum.any?(&File.exists?/1)
    end

    deleted or prereqs_outdated or prereqsne_created
  end

  def md5(string) do
    :crypto.hash(:md5, string) |> Base.encode16 |> String.downcase
  end

  def redo_ifcreate() do
    unless System.get_env("REDOPARENT"), do: exit "no parent"

    System.argv()
    |> Enum.each(&redo_ifcreate(&1, System.get_env("REDOPARENT")))
  end

  def redo_ifcreate(file, redoparent) do
    unless File.exists?(".redo/#{Path.dirname(file)}"), do: File.mkdir(".redo/#{Path.dirname(file)}")
    if File.exists?(file), do: exit "#{file} exists"

    parent_file = ".redo/#{redoparent}.prereqsne.build"
    File.write("#{parent_file}---new", file)
    File.rename("#{parent_file}---new", parent_file)
  end
end