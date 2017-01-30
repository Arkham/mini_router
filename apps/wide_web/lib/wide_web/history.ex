defmodule WideWeb.History do
  defstruct root: nil, data: %{}

  def new(root) do
    %__MODULE__{root: root}
  end

  def check(%__MODULE__{root: root}, root, _count), do: :old
  def check(%__MODULE__{data: data} = history, node, count) do
    current_count = Map.get(data, node, 0)

    if count > current_count do
      {:new, %__MODULE__{history | data: Map.put(data, node, count)}}
    else
      :old
    end
  end
end
