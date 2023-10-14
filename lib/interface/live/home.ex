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
    <main class="flex flex-col h-screen bg-gray-800 text-gray-50">
      <header class="flex items-center h-14 px-4 border-b bg-gray-900 border-gray-700">
        <h1 class="font-bold">
          Core
        </h1>
      </header>
      <div class="grow">
        <div class="flex h-full">
          <div class="w-3/12 p-4 border-r bg-gray-900 border-gray-700">
            <button
              phx-click={if(@backend.running?, do: "stop_backend", else: "start_backend")}
              class="w-full p-2 bg-gray-500 border border-gray-400 uppercase text-sm text-left hover:bg-gray-400"
            >
              <%= if @backend.running? do %>
                Stop server
              <% else %>
                Start server
              <% end %>
            </button>

            <hr class="border-t border-gray-700 my-4" />

            <p>
              <span class="block opacity-50">Starting command</span>
              <%= Enum.join(Core.Backend.Config.to_cmd_format(@backend.config), " ") %>
            </p>
          </div>

          <div class="w-9/12 p-4">
            <input value={@command} class="w-full bg-gray-400 p-2 py-1.5 border border-gray-400" phx-keydown="send" phx-key="enter" />

            <hr class="border-t border-gray-700 my-4" />

            <div>
              <%= for %{time: time, event: event, payload: payload} <- @events do %>
                <div class="flex gap-2 items-center">
                  <span class="opacity-50 text-sm">
                    <%= time %>
                  </span>
                  <span :if={event === "server"} class="">_</span>
                  <span :if={event === "send"} class="">»</span>
                  <span :if={event === "receive"} class="">«</span>
                  <span class="">
                    <%= payload %>
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <footer class="relative flex items-center px-4 h-14 border-t bg-gray-900 border-gray-700">
        <div class="flex items-center gap-4 text-sm">
          <div class={[
            "w-3 h-3 rounded-full",
            @backend.running? == true && "bg-green",
            @backend.running? == false && "bg-gray-500",
            @backend.running? == :undefined && "bg-peach"
          ]}>
          </div>
          <div :if={@backend.socket} class="flex">
            <span class="opacity-50">Socket</span>
            <%= inspect(@backend.socket) |> String.replace_leading("#Port", "") %>
          </div>
        </div>

        <div class="absolute flex gap-3 top-3 right-3 bottom-3">
          <.flash_group flash={@flash} />
        </div>
      </footer>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("start_backend", _value, socket) do
    case GenServer.call(BackendServer, :start) do
      {:ok, :starting} ->
        {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("stop_backend", _value, socket) do
    case GenServer.call(BackendServer, :stop) do
      {:ok, :stopping} ->
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

    GenServer.call(BackendServer, {:send, address, args})
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: topic, event: event, payload: payload}, socket) when topic == socket.assigns.topic do
    time = DateTime.utc_now() |> DateTime.to_time()
    message = %{time: time, event: event, payload: payload}

    socket =
      socket
      |> assign(:backend, GenServer.call(BackendServer, :get_state))
      |> assign(:events, [message | socket.assigns.events])

    {:noreply, socket}
  end
end
