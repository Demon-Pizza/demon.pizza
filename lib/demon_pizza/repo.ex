defmodule DemonPizza.Repo do
  use Ecto.Repo,
    otp_app: :demon_pizza,
    adapter: Ecto.Adapters.Postgres
end
