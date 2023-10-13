defmodule Interface.Live.Home do
  @moduledoc """
  Home
  """

  use Interface, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    topic = "logging-server"

    if connected?(socket) do
      Interface.Endpoint.subscribe(topic)
    end

    socket =
      socket
      |> assign(page_title: "Core")
      |> assign(topic: topic)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:page_title, "Core")
      |> assign(:backend, GenServer.call(BackendServer, :get_state))
      |> assign(:command, "/s_new, piano, 117")
      |> assign(:events, [])

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
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
    <hr />

    <div>
      <%= for event <- @events do %>
        <p><%= event %></p>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("refresh", _value, socket) do
    {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}
  end

  @impl Phoenix.LiveView
  def handle_event("start_backend", _value, socket) do
    case GenServer.call(BackendServer, :start) do
      {:ok, :running} ->
        {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("stop_backend", _value, socket) do
    case GenServer.call(BackendServer, :stop) do
      {:ok, :stopped} ->
        {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
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

    {:ok, :sent} = GenServer.call(BackendServer, {:send, address, args})
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: topic, event: event, payload: payload}, socket) when topic == socket.assigns.topic do
    symbol =
      case event do
        "server" -> "_"
        "send" -> ">"
        "receive" -> "<"
      end

    time = DateTime.utc_now() |> DateTime.to_time()
    message = "#{time} #{symbol} #{payload}"

    {:noreply, assign(socket, :events, [message | socket.assigns.events])}
  end
end
