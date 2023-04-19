defmodule Core.Backend.Server do
  @moduledoc false

  use GenServer

  alias Core.Backend.Config
  alias Core.Backend.Server
  alias Core.Socket.Socket

  require Logger

  defstruct running?: false, config: %Config{}, wrapper: nil, socket: nil

  @type t :: %Server{
          running?: boolean(),
          config: Config.t(),
          wrapper: Port.t() | nil,
          socket: Port.t() | nil
        }

  @spec start_link(any()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(arg \\ nil) do
    GenServer.start_link(Server, arg, name: BackendServer)
  end

  @spec init(any()) :: {:ok, Server.t()}
  def init(_args) do
    {:ok, %Server{}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:running?, _from, %{running?: false} = state) do
    {:reply, {:ok, :not_running}, state}
  end

  def handle_call(:running?, _from, %{running?: true} = state) do
    {:reply, {:ok, :running}, state}
  end

  def handle_call(:start, _from, %{running?: false} = state) do
    options = [
      :binary,
      :exit_status,
      {:env,
       [
         {'SC_JACK_DEFAULT_OUTPUTS', String.to_charlist(state.config.jack_out)},
         {'SC_JACK_DEFAULT_INPUTS', String.to_charlist(state.config.jack_in)}
       ]},
      args: Config.to_cmd_format(state.config)
    ]

    wrapper_path = Path.join([File.cwd!(), state.config.wrapper_path])
    wrapper_port = Port.open({:spawn_executable, wrapper_path}, options)

    {:reply, {:ok, :running}, %{state | running?: true, wrapper: wrapper_port}}
  end

  def handle_call(:start, _from, state) do
    {:reply, {:error, "Supernova already running"}, state}
  end

  def handle_call(:stop, _from, %{running?: false} = state) do
    {:reply, {:error, "Supernova not running"}, state}
  end

  def handle_call(:stop, _from, state) do
    state = %{state | running?: false, wrapper: nil, socket: nil}
    {:reply, {:ok, :not_running?}, state}
  end

  def handle_call({:send, address, args}, _from, %{running?: true} = state) when is_list(args) do
    message = %OSC.Message{address: address, arguments: args}
    {:ok, encoded} = OSC.encode(message)

    Socket.send(state, encoded)
    Logger.notice("Send > #{message.address}, #{inspect(message.arguments)}")

    {:reply, :ok, state}
  end

  def handle_info({_port, {:data, data}}, state) do
    if String.match?(data, ~r/SuperCollider 3 server ready./) do
      Logger.notice("Supercollider started!")

      {:ok, state} = Socket.open(state)
      Logger.notice("Socket opened on #{inspect(state.socket)}")

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:tcp, _socket, data}, state) do
    {:ok, %OSC.Packet{contents: message}} = OSC.decode(data)
    Logger.notice("Receive > #{message.address}, #{inspect(message.arguments)}")

    {:noreply, state}
  end

  def handle_info({:udp, _socket, _address, _port, data}, state) do
    {:ok, %OSC.Packet{contents: message}} = OSC.decode(data)
    Logger.notice("Receive > #{message.address}, #{inspect(message.arguments)}")

    {:noreply, state}
  end
end

# { [SinOsc.ar(440, 0, 0.2), SinOsc.ar(442, 0, 0.2)] }.play;
