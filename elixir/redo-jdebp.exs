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

    if File.exists?(".redo/#{file}.do") do
      # redo_ifchange("#{file}.do", file)
      # buildfile = "#{file}.do"
    else
      default = Regex.replace(~r/.*([.][^.]*)$/, file, "default\\1.do")
      |> IO.inspect()
      if File.exists?(".redo/#{default}.do") do
        # buildfile = "#{default}.do"
        # redo_ifchange("#{default}.do", file)
        # redo_ifcreate("#{file}.do", file)
      else
        {:error, "#{file}: no build script (#{default}.do) found"}
      end
    end
	  # basefile = Regex.replace(~r/\..*$/, file, "")
    Path.wildcard(".redo/#{file}.{uptodate,redoing}")
    |> Enum.each(&File.rm/1)

    "#{file}.redoing"
    |> File.write("redoing")

    # if r=0 do

  end
end

Redo.redo()