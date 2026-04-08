defmodule PrometheusEntry.Controllers.ErrorJSON do
  @moduledoc false
	def render(template, _assigns) do
	  %{success: false, errors: [%{code: template, message: Phoenix.Controller.status_message_from_template(template)}]}
  end
end
