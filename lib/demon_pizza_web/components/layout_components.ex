defmodule DemonPizzaWeb.LayoutComponents do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DemonPizzaWeb.Endpoint,
    router: DemonPizzaWeb.Router,
    statics: DemonPizzaWeb.static_paths()

  import DemonPizzaWeb.CoreComponents

  embed_templates "layouts/layout.html"
  slot :inner_block
  def layout(assigns)
end
