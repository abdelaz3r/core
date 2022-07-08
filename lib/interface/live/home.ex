defmodule Interface.Live.Home do
  @moduledoc """
  Home
  """

  use Interface, :live_view

  require Logger

  def render(assigns) do
    ~H"""
    <h1>Core</h1>

    <hr>

    <p>Backend state: <%= @backend %></p>
    <p>
      <button phx-click="start_backend">Start Backend</button>
      <button phx-click="stop_backend">Stop Backend</button>
    </p>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:ok, backend_state} = GenServer.call(BackendServer, :running?)

    socket =
      socket
      |> assign(:page_title, "Core")
      |> assign(:backend, backend_state)

    {:noreply, socket}
  end

  def handle_event("start_backend", _value, socket) do
    case GenServer.call(BackendServer, :start) do
      {:ok, backend_state} ->
        Logger.info("Started")
        {:noreply, assign(socket, :backend, backend_state)}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end

  def handle_event("stop_backend", _value, socket) do
    case GenServer.call(BackendServer, :stop) do
      {:ok, backend_state} ->
        Logger.info("Stopped")
        {:noreply, assign(socket, :backend, backend_state)}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end
end
