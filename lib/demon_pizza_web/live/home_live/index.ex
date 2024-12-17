defmodule DemonPizzaWeb.HomeLive.Index do
  use DemonPizzaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page: 1, per_page: 20)
     |> stream_configure(:pizzerias, dom_id: &"pizzeriasc-#{&1.pizzeria.id}")
     |> paginate_pizzerias(1)}
  end

  def handle_event("next-page", _, socket) do
    {:noreply, paginate_pizzerias(socket, socket.assigns.page + 1)}
  end

  # def handle_event("prev-page", %{"_overran" => true}, socket) do
  #   {:noreply, paginate_pizzerias(socket, 1)}
  # end

  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_pizzerias(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp paginate_pizzerias(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns

    pizzerias =
      DemonPizza.Pizzerias.list_pizzerias(offset: (new_page - 1) * per_page, limit: per_page)

    {pizzerias, at, limit} =
      if new_page >= cur_page do
        {pizzerias, -1, per_page * 3 * -1}
      else
        {Enum.reverse(pizzerias), 0, per_page * 3}
      end

    case pizzerias do
      [] ->
        assign(socket, end_of_timeline?: at == -1)

      [_ | _] = pizzerias ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(:page, new_page)
        |> stream(:pizzerias, pizzerias, at: at, limit: limit)
    end
  end
end
