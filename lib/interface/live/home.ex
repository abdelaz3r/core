defmodule Interface.Live.Home do
  @moduledoc """
  Home
  """

  use Interface, :live_view

  alias SuperCollider

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
      |> assign(
        commands: [
          {"Get version", "/version"},
          {"Get server status", "/status"},
          {"Set notify", "/notify, 1"},
          {"Load sonicpi synth directory",
           "/d_loadDir, /Users/abdelaz3r/Documents/dev/sonic-pi/etc/synthdefs/compiled/"},
          {"Load test synth", "/d_load, /Users/abdelaz3r/Documents/dev/test.scsyndef"},
          {"Create test synth", "/s_new, tutorial-SinOsc-stereo, 100, 1, 0"},
          {"Free test synth", "/n_free, 100"},
          {"Quit server", "/quit"}
        ]
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:page_title, "Core")
      |> assign(:backend, GenServer.call(BackendServer, :get_state))
      |> assign(:command, "/s_new, piano, 117")
      |> assign(:async_time, "1")
      |> assign(:async_command, "")
      |> assign(:events, [])

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="h-screen bg-gray-800 text-gray-50">
      <header class="flex items-center h-14 px-4 border-b bg-gray-950 border-gray-700">
        <h1 class="font-bold">
          Core
        </h1>
      </header>

      <div class="flex h-[calc(100%-7rem)] overflow-hidden">
        <div class="w-80 p-4 border-r bg-gray-900 border-gray-700">
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

          <div :if={@backend.running? === true}>
            <hr class="border-t border-gray-700 my-4" />

            <button
              :for={{label, command} <- @commands}
              phx-click="set_command"
              phx-value-command={command}
              class="w-full p-2 mb-2 bg-gray-500 border border-gray-400 uppercase text-sm text-left hover:bg-gray-400"
            >
              <%= label %>
            </button>
          </div>
        </div>

        <div class="flex flex-1 flex-col w-full">
          <div class="h-18 flex-1 border-b border-gray-600">
            <input
              value={@command}
              class="w-full p-4 border-none !outline-none bg-gray-700 hover:bg-gray-700/50 focus:bg-gray-700/50"
              phx-keydown="send"
              phx-key="enter"
              placeholder="sync command"
            />
          </div>
          <.form
            :let={f}
            for={%{"time" => @async_time, "command" => @async_command}}
            as={:send_async}
            phx-submit="send_async"
            class="flex h-18 flex-1 border-b border-gray-600"
          >
            <input
              id={f["time"].id}
              name={f["time"].name}
              value={f["time"].value}
              class="w-28 p-4 border-r border-gray-600 !outline-none bg-gray-700 hover:bg-gray-700/50 focus:bg-gray-700/50"
              placeholder="delay"
            />
            <input
              id={f["command"].id}
              name={f["command"].name}
              value={f["command"].value}
              class="w-full p-4 border-none !outline-none bg-gray-700 hover:bg-gray-700/50 focus:bg-gray-700/50"
              placeholder="async command"
            />
            <button class="hidden"></button>
          </.form>
          <div class="h-full p-4 grow overflow-y-scroll">
            <%= for event <- @events do %>
              <div class="flex gap-2 items-center hover:bg-gray-700">
                <span class="opacity-50 text-sm">
                  <%= event.time %>
                </span>
                <span :if={event.type === "server"} class="">_</span>
                <span :if={event.type === "send"} class="">»</span>
                <span :if={event.type === "receive"} class="">«</span>
                <span :if={event.prefix} class={event.prefix_color}>
                  <%= event.prefix %>
                </span>
                <span class="">
                  <%= event.message %>
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <footer class="relative flex items-center px-4 h-14 border-t bg-gray-950 border-gray-700">
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
    IO.inspect("starting server")
    server = SuperCollider.start()
    IO.inspect(server)
    :timer.sleep(2000)

    IO.inspect(SuperCollider.command(:status))
    :timer.sleep(2000)
    IO.inspect(SuperCollider.response()[:status])
    :timer.sleep(2000)

    {:noreply, socket}

    # case GenServer.call(BackendServer, :start, 20_000) do
    #   {:ok, :starting} ->
    #     {:noreply, assign(socket, :backend, GenServer.call(BackendServer, :get_state))}

    #   {:error, _reason} ->
    #     {:noreply, socket}
    # end
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
  def handle_event("set_command", %{"command" => command}, socket) do
    {:noreply, assign(socket, :command, command)}
  end

  @impl Phoenix.LiveView
  def handle_event("send", %{"value" => value}, socket) when value !== "" do
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

    GenServer.call(BackendServer, {:send, {address, args}})
    {:noreply, assign(socket, :command, value)}
  end

  def handle_event("send", _payload, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send_async", %{"send_async" => %{"time" => time, "command" => value}}, socket)
      when value !== "" and time !== "" do
    time = String.to_integer(time)

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

    GenServer.call(BackendServer, {:send, {time, address, args}})

    socket =
      socket
      |> assign(:async_time, time)
      |> assign(:async_command, value)

    {:noreply, socket}
  end

  def handle_event("send_async", _payload, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %{topic: topic, event: type, payload: %{prefix: prefix, prefix_color: prefix_color, payload: payload}},
        socket
      )
      when topic == socket.assigns.topic do
    {:noreply, log_and_refresh(socket, type, payload, prefix, prefix_color)}
  end

  def handle_info(%{topic: topic, event: type, payload: %{prefix: prefix, payload: payload}}, socket)
      when topic == socket.assigns.topic do
    {:noreply, log_and_refresh(socket, type, payload, prefix, "text-green")}
  end

  def handle_info(%{topic: topic, event: type, payload: payload}, socket) when topic == socket.assigns.topic do
    {:noreply, log_and_refresh(socket, type, payload, nil, nil)}
  end

  defp log_and_refresh(socket, type, message, prefix, prefix_color) do
    time = DateTime.utc_now() |> DateTime.to_time()
    event = %{time: time, type: type, message: message, prefix: prefix, prefix_color: prefix_color}

    socket
    |> assign(:backend, GenServer.call(BackendServer, :get_state))
    |> assign(:events, [event | socket.assigns.events])
  end
end
