defmodule Interface.ErrorView do
  use Interface, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  @doc """
  HTTP 403 error template.
  """
  #  Default
  def render("403.html", _assigns) do
    "Forbidden"
  end
end
