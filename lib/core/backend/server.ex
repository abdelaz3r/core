defmodule Core.Backend.Server do
  @moduledoc false

  use GenServer

  alias Core.Backend.Config
  alias Core.Backend.Server
  alias Core.Socket.Socket
  alias Interface.Endpoint

  @unix_epoch 2_208_988_800

  defstruct running?: false,
            config: %Config{},
            wrapper: nil,
            socket: nil,
            logger: "logging-server"

  @type t :: %Server{
          running?: boolean() | :undefined,
          config: Config.t(),
          wrapper: Port.t() | nil,
          socket: Port.t() | nil,
          logger: String.t()
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

  def handle_call(:running?, _from, %{running?: :undefined} = state) do
    {:reply, {:ok, :undefined}, state}
  end

  def handle_call(:start, _from, %{running?: false} = state) do
    options = [
      :binary,
      :exit_status,
      {:env,
       [
         {~c"SC_JACK_DEFAULT_OUTPUTS", String.to_charlist(state.config.jack_out)},
         {~c"SC_JACK_DEFAULT_INPUTS", String.to_charlist(state.config.jack_in)}
       ]},
      args: Config.to_cmd_format(state.config)
    ]

    wrapper_path = Path.join([File.cwd!(), state.config.wrapper_path])
    wrapper_port = Port.open({:spawn_executable, wrapper_path}, options)

    {:reply, {:ok, :starting}, %{state | running?: :undefined, wrapper: wrapper_port}}
  end

  def handle_call(:start, _from, state) do
    {:reply, {:error, :server_already_running}, state}
  end

  def handle_call(:stop, _from, %{running?: true} = state) do
    Port.close(state.wrapper)
    state = %{state | running?: :undefined}

    {:reply, {:ok, :stopping}, state}
  end

  def handle_call(:stop, _from, state) do
    {:reply, {:error, :server_not_running}, state}
  end

  def handle_call({:send, {address, args}}, _from, %{running?: true} = state) when is_list(args) do
    message = %OSC.Message{address: address, arguments: args}

    {:ok, encoded} = OSC.encode(message)
    Socket.send(state, encoded)

    Endpoint.broadcast(state.logger, "send", %{
      prefix: message.address,
      payload: message.arguments |> Enum.join(", ")
    })

    {:reply, {:ok, :sent}, state}
  end

  def handle_call({:send, {run_after, address, args}}, _from, %{running?: true} = state) when is_list(args) do
    seconds = System.os_time(:second) + @unix_epoch + run_after
    timetag = %OSC.TimeTag{seconds: seconds, fraction: 0}
    message = %OSC.Message{address: address, arguments: args}

    {:ok, encoded} = OSC.encode(%OSC.Bundle{time: timetag, elements: [message]})
    Socket.send(state, encoded)

    Endpoint.broadcast(state.logger, "send", %{
      prefix: message.address,
      payload: (["[send in #{run_after} | real:#{seconds}]"] ++ message.arguments) |> Enum.join(", ")
    })

    {:reply, {:ok, :sent}, state}
  end

  def handle_call({:send, _message}, _from, state) do
    Endpoint.broadcast(state.logger, "send", %{
      prefix: "/error",
      prefix_color: "text-red",
      payload: "Supercollider not started or starting"
    })

    {:reply, {:error, :not_sent}, state}
  end

  def handle_info({_port, {:data, data}}, state) do
    if String.match?(data, ~r/SuperCollider 3 server ready./) do
      Endpoint.broadcast(state.logger, "server", "Supercollider started")

      {:ok, state} = Socket.open(state)
      Endpoint.broadcast(state.logger, "server", "Socket opened on #{inspect(state.socket)}")

      {:noreply, %{state | running?: true}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:tcp, _socket, data}, state) do
    {:ok, %OSC.Packet{contents: message}} = OSC.decode(data)

    Endpoint.broadcast(state.logger, "receive", %{
      prefix: message.address,
      payload: message.arguments |> Enum.join(", ")
    })

    {:noreply, state}
  end

  def handle_info({:udp, _socket, _address, _port, data}, state) do
    {:ok, %OSC.Packet{contents: message}} = OSC.decode(data)

    Endpoint.broadcast(state.logger, "receive", %{
      prefix: message.address,
      payload: message.arguments |> Enum.join(", ")
    })

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Endpoint.broadcast(state.logger, "server", "Supercollider stopped")
    {:noreply, %{state | running?: false, wrapper: nil, socket: nil}}
  end

  def handle_info({_port, {:exit_status, 0}}, state) do
    Endpoint.broadcast(state.logger, "server", "Wrapper killed")
    {:noreply, %{state | running?: false, wrapper: nil, socket: nil}}
  end
end
