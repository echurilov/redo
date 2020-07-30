defmodule Redo do
  def redo() do 
    unless File.exists?(".redo"), do: File.mkdir(".redo")
    msg()
  end

  def msg() do
    
  end
end

Redo.redo()