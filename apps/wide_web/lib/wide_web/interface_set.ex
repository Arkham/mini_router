defmodule WideWeb.InterfaceSet do
  defstruct data: %{}

  def new, do: %__MODULE__{}

  def add(%__MODULE__{data: data} = set, name, ref, pid) do
    %__MODULE__{set | data: Map.put(data, name, {ref, pid})}
  end

  def remove(%__MODULE__{data: data} = set, name) do
    %__MODULE__{set | data: Map.delete(data, name)}
  end

  def lookup(%__MODULE__{data: data}, name) do
    case Map.fetch(data, name) do
      {:ok, {_ref, pid}} -> {:ok, pid}
      :error             -> :not_found
    end
  end

  def ref(%__MODULE__{data: data}, name) do
    case Map.fetch(data, name) do
      {:ok, {ref, _pid}} -> {:ok, ref}
      :error             -> :not_found
    end
  end

  def name(%__MODULE__{data: data}, ref) do
    result = data
             |> Map.to_list
             |> Enum.find(fn({_name, {r, _}}) -> r == ref end)

    case result do
      {name, {^ref, _}} -> {:ok, name}
      _ -> :not_found
    end
  end

  def list(%__MODULE__{data: data}) do
    Map.keys(data)
  end

  def broadcast(%__MODULE__{data: data}, message) do
    data
    |> Enum.each(fn({_name, {_ref, pid}}) ->
      send(pid, message)
    end)
  end
end
