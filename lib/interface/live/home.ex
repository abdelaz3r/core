defmodule Interface.Live.Home do
  @moduledoc """
  Home
  """

  use Interface, :live_view

  require Logger

  def render(assigns) do
    ~H"""
    <h1>Core</h1>
    <hr />

    <p>Running? -> <%= @backend.running? %></p>
    <p>Socket -> <%= inspect(@backend.socket) %></p>
    <p>Wrapper -> <%= inspect(@backend.wrapper) %></p>
    <hr />

    <p>Cmd -> <%= Enum.join(Core.Backend.Config.to_cmd_format(@backend.config), " ") %></p>
    <p><button phx-click="refresh">Refresh</button></p>
    <hr />

    <p>
      <button phx-click="start_backend">Start Backend</button>
      <button phx-click="stop_backend">Stop Backend</button>
    </p>
    <hr />

    <input value={@command} phx-keydown="send" phx-key="enter" />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:page_title, "Core")
      |> assign(:backend, GenServer.call(BackendServer, :get_state))
      |> assign(:command, "/s_new, piano, 117")

    {:noreply, socket}
  end

  def handle_event("refresh", _value, socket) do
    {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}
  end

  def handle_event("start_backend", _value, socket) do
    case GenServer.call(BackendServer, :start) do
      {:ok, _backend_state} ->
        Logger.info("Started")
        {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end

  def handle_event("stop_backend", _value, socket) do
    case GenServer.call(BackendServer, :stop) do
      {:ok, _backend_state} ->
        Logger.info("Stopped")
        {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end

  def handle_event("send", %{"value" => value}, socket) do
    [address | args] =
      value
      |> String.split(",", trim: true)
      |> Enum.map(fn part ->
        part = String.trim(part)

        case Integer.parse(part) do
          {integer, rest} when rest == "" -> integer
          _ -> part
        end
      end)

    GenServer.call(BackendServer, {:send, address, args})
    {:noreply, socket}
  end
end
