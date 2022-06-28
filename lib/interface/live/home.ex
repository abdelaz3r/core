defmodule Interface.Live.Home do
  @moduledoc """
  Home
  """

  use Interface, :live_view

  def render(assigns) do
    ~H"""
    Core
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Core")
      |> assign(:test, 1)

    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
