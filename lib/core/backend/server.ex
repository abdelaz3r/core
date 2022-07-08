defmodule Core.Backend.Server do
  @moduledoc false

  use GenServer

  @wrapper_path "/Users/gilclavien/Documents/music/core/scripts/backend-wrapper.sh"
  @backend_path "/Applications/SuperCollider.app/Contents/Resources/supernova"
  @backend_data ~r/Supernova ready/

  @spec start_link(any()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(arg \\ nil) do
    GenServer.start_link(__MODULE__, arg, name: BackendServer)
  end

  @spec init(any()) :: {:ok, nil}
  def init(_args) do
    {:ok, nil}
  end

  def handle_call(:running?, _from, nil) do
    {:reply, {:ok, :not_running}, nil}
  end

  def handle_call(:running?, _from, state) do
    {:reply, {:ok, :running}, state}
  end

  def handle_call(:start, _from, nil) do
    task =
      Task.async(fn ->
        process = %Porcelain.Process{out: stream} = Porcelain.spawn(@wrapper_path, [@backend_path], out: :stream)
        _result = Enum.find(stream, fn line -> String.match?(line, @backend_data) end)
        process
      end)

    case Task.yield(task, 10_000) || Task.shutdown(task) do
      {:ok, process} -> {:reply, {:ok, :running}, process}
      nil -> {:reply, {:error, "Supernova starting failed"}, nil}
    end
  end

  def handle_call(:start, _from, state) do
    {:reply, {:error, "Supernova already running"}, state}
  end

  def handle_call(:stop, _from, nil) do
    {:reply, {:error, "Supernova not running"}, nil}
  end

  def handle_call(:stop, _from, state) do
    Porcelain.Process.stop(state)
    {:reply, {:ok, :not_running?}, nil}
  end
end
