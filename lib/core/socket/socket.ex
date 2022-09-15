defmodule Core.Socket.Socket do
  @moduledoc false

  alias Core.Backend.Server

  @spec open(Server.t()) :: {:ok, Server.t()} | {:errror, atom(), Server.t()}
  def open(server) when server.config.protocol == :tcp do
    case :gen_tcp.connect('localhost', server.config.port, [:binary, active: true, packet: 4]) do
      {:ok, socket} -> {:ok, %{server | socket: socket}}
      {:error, reason} -> {:error, reason, server}
    end
  end

  def open(server) when server.config.protocol == :udp do
    case :gen_udp.open(0, [:binary, {:active, true}]) do
      {:ok, socket} -> {:ok, %{server | socket: socket}}
      {:error, reason} -> {:error, reason, server}
    end
  end

  @spec send(Server.t(), iodata() | String.t()) :: :ok
  def send(server, data) when server.config.protocol == :tcp do
    :gen_tcp.send(server.socket, data)
  end

  def send(server, data) when server.config.protocol == :udp do
    :gen_udp.send(server.socket, 'localhost', server.config.port, data)
  end
end
